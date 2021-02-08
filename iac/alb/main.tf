resource "aws_security_group" "http_sg" {
    name = "HTTP SG"

    ingress {
        from_port = var.alb_listen_port
        to_port = var.alb_listen_port
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_alb" "alb" {
    name = "aws-poc-alb"
    subnets = slice(var.nginx_subnet_ids, 0, 2)
    security_groups = [aws_security_group.http_sg.id]
    internal = false
}

resource "aws_alb_listener" "alb_listener" {
    load_balancer_arn = aws_alb.alb.arn
    port = var.alb_listen_port
    protocol = "HTTP"

    default_action {
        type = "forward"

        forward {
            target_group {
                arn = aws_alb_target_group.nginx_group.arn
                weight = var.nginx_weight
            }

            target_group {
                arn = aws_alb_target_group.lambda_group.arn
                weight = var.lambda_weight
            }
        }
    }
}

resource "aws_alb_listener_rule" "time_only" {
    depends_on = [aws_alb_target_group.lambda_group]
    listener_arn = aws_alb_listener.alb_listener.arn

    action {
        type = "forward"
        target_group_arn = aws_alb_target_group.lambda_group.arn
    }

    condition {
        path_pattern {
            values = [var.time_only_endpoint]
        }
    }
}

resource "aws_alb_target_group" "lambda_group" {
    name = "time-lambda-group"
    target_type = "lambda"
}

resource "aws_lambda_permission" "with_alb" {
    statement_id = "AllowExecutionFromlb"
    action = "lambda:InvokeFunction"
    function_name = var.lambda_arn
    principal = "elasticloadbalancing.amazonaws.com"
    source_arn = aws_alb_target_group.lambda_group.arn
}

resource "aws_alb_target_group_attachment" "lambda_attachment" {
    target_group_arn = aws_alb_target_group.lambda_group.arn
    target_id = var.lambda_arn
    depends_on = [aws_lambda_permission.with_alb]
}

resource "aws_alb_target_group" "nginx_group" {
    name = "name-nginx-group"
    port = var.alb_listen_port
    protocol = "HTTP"
    vpc_id = aws_security_group.http_sg.vpc_id
}

resource "aws_alb_target_group_attachment" "nginx_attachment" {
    target_group_arn = aws_alb_target_group.nginx_group.arn
    target_id = var.nginx_server_ids[count.index]
    port = var.nginx_listen_port
    count = length(var.nginx_server_ids)
}


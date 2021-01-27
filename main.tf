provider "aws" {
    region = "eu-central-1"
}


# Instance variables

variable "image_id" {
    type = string
    default = "ami-0502e817a62226e03"
}

variable "flavor" {
    type = string
    default = "t2.micro"
}

variable "ingress_ports" {
    type = list(number)
    default = [22, 8080]
}

variable "public_key" {
    type = string
    sensitive = true
}


# Instance resources

resource "aws_security_group" "ssh_and_web" {
    name = "SSH & WEB"

    dynamic "ingress" {
        iterator = port 
        for_each = var.ingress_ports
        content {
            from_port = port.value
            to_port = port.value
            protocol = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
       from_port = 0
       to_port = 0
       protocol = "-1"
       cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "poc_key" {
  key_name   = "AWS POC Key"
  public_key = var.public_key
}

resource "aws_instance" "nginx1" {
    ami = var.image_id
    instance_type = var.flavor
    security_groups = [aws_security_group.ssh_and_web.name]
    key_name = aws_key_pair.poc_key.key_name
    availability_zone = "eu-central-1b"
    tags = {
        Name = "NGINX1"
    }
}

resource "aws_instance" "nginx2" {
    ami = var.image_id
    instance_type = var.flavor
    security_groups = [aws_security_group.ssh_and_web.name]
    key_name = aws_key_pair.poc_key.key_name
    availability_zone = "eu-central-1c"
    tags = {
        Name = "NGINX2"
    }
}


# Instance outputs

output "nginx1_public_ip" {
    value = aws_instance.nginx1.public_ip
}

output "nginx2_public_ip" {
    value = aws_instance.nginx2.public_ip
}


# Lambda resources

resource "aws_iam_role" "lambda_exec_role" {
  name        = "lambda_exec"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda_function" {
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda.handler"
  runtime          = "python3.8"
  filename         = "lambda.zip"
  function_name    = "time_func"
  source_code_hash = filebase64sha256("lambda.zip")
}


# ALB resources

resource "aws_security_group" "http_sg" {
    name = "HTTP SG"

    ingress {
        from_port = 80
        to_port = 80
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
    subnets = [aws_instance.nginx1.subnet_id, aws_instance.nginx2.subnet_id]
    security_groups = [aws_security_group.http_sg.id]
    internal = false
}

resource "aws_alb_listener" "alb_listener" {  
    load_balancer_arn = aws_alb.alb.arn
    port = 80
    protocol = "HTTP"
  
    default_action {    
        type = "forward"
    
        forward {
            target_group {
                arn = aws_alb_target_group.lambda_group.arn
                weight = 5
            }

            target_group {
                arn = aws_alb_target_group.nginx_group.arn
                weight = 5
            }
        }
    }
}

resource "aws_alb_listener_rule" "time_only" {
    depends_on = [aws_alb_target_group.lambda_group]
    listener_arn = aws_alb_listener.alb_listener.arn
    priority = 100
  
    action {
        type = "forward"
        target_group_arn = aws_alb_target_group.lambda_group.arn
    }
  
    condition {
        path_pattern {
            values = ["/time"]
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
    function_name = aws_lambda_function.lambda_function.arn
    principal = "elasticloadbalancing.amazonaws.com"
    source_arn = aws_alb_target_group.lambda_group.arn
}

resource "aws_alb_target_group_attachment" "lambda_attachment" {
    target_group_arn = aws_alb_target_group.lambda_group.arn
    target_id = aws_lambda_function.lambda_function.arn
    depends_on = [aws_lambda_permission.with_alb]
}

resource "aws_alb_target_group" "nginx_group" {
    name = "name-nginx-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_security_group.http_sg.vpc_id
}

resource "aws_alb_target_group_attachment" "nginx1_attachment" {
    target_group_arn = aws_alb_target_group.nginx_group.arn
    target_id = aws_instance.nginx1.id
    port = 8080
}

resource "aws_alb_target_group_attachment" "nginx2_attachment" {
    target_group_arn = aws_alb_target_group.nginx_group.arn
    target_id = aws_instance.nginx2.id
    port = 8080
}


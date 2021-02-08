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
    key_name = "AWS POC Key"
    public_key = var.public_key
}

resource "aws_instance" "nginx" {
    for_each = var.nginx_servers
    ami = var.image_id
    instance_type = var.flavor
    security_groups = [aws_security_group.ssh_and_web.name]
    key_name = aws_key_pair.poc_key.key_name
    availability_zone = each.value
    tags = {
        Name = each.key
    }
}


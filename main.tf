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

variable "egress_ports" {
    type = list(number)
    default = [80, 8080, 443]
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

    dynamic "egress" {
        iterator = port 
        for_each = var.egress_ports
        content {
            from_port = port.value
            to_port = port.value
            protocol = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }
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
    tags = {
        Name = "NGINX1"
    }
}

resource "aws_instance" "nginx2" {
    ami = var.image_id
    instance_type = var.flavor
    security_groups = [aws_security_group.ssh_and_web.name]
    key_name = aws_key_pair.poc_key.key_name
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


provider "aws" {
    region = "eu-central-1"
}

variable "public_key" {
    type = string
    sensitive = true
}

module "nginx" {
    source = "./nginx"
    public_key = var.public_key
}

module "lambda" {
    source = "./lambda"
}

module "alb" {
    source = "./alb"
    nginx_server_ids = module.nginx.server_ids
    nginx_subnet_ids = module.nginx.subnet_ids
    lambda_arn = module.lambda.arn
}

output "nginx_public_ips" {
    value = module.nginx.public_ips
}

output "alb_dns_name" {
    value = module.alb.dns_name
}


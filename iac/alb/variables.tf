variable "alb_listen_port" {
    type = number
    default = 80
}

variable "nginx_listen_port" {
    type = number
    default = 8080
}

variable "nginx_server_ids" {
    type = list(string)
}

variable "nginx_subnet_ids" {
    type = list(string)
}

variable "nginx_weight" {
    type = number
    default = 5
}

variable "lambda_arn" {
    type = string
}

variable "lambda_weight" {
    type = number
    default = 5
}

variable "time_only_endpoint" {
    type = string
    default = "/time"
}


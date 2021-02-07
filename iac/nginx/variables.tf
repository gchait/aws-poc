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

variable "nginx_servers" {
    type = map(string)
    default = {
        NGINX1 = "eu-central-1b"
        NGINX2 = "eu-central-1c"
    }
}


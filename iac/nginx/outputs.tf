output "server_ids" {
    value = [for server in aws_instance.nginx: server.id]
}

output "subnet_ids" {
    value = [for server in aws_instance.nginx: server.subnet_id]
}

output "public_ips" {
    value = [for server in aws_instance.nginx: join(" ", [server.tags.Name, server.public_ip])]
}


#!/bin/bash

echo "[nginx_servers]" > ../ansible/hosts
grep "NGINX. " terraform.tfstate | tr -d '",' | awk '{print $1 " ansible_host=" $2}' >> ../ansible/hosts


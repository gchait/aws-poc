#!/bin/bash

NGINX1_IP=$(grep -A1 nginx1_public_ip terraform.tfstate | grep value | awk '{print $2}' | tr -d '",')
NGINX2_IP=$(grep -A1 nginx2_public_ip terraform.tfstate | grep value | awk '{print $2}' | tr -d '",')

echo "[nginx_servers]" > ansible/hosts
echo "NGINX1 ansible_host=$NGINX1_IP" >> ansible/hosts
echo "NGINX2 ansible_host=$NGINX2_IP" >> ansible/hosts


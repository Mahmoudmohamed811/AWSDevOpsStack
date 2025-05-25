#!/bin/bash


# Clear or create the inventory file
> inventory.ini

# Write groups and hosts with IPs from terraform output
{
  echo "[grafana]"
  (cd ../terraform && terraform output -raw grafana_instance)
  echo ""

  echo "[prometheus]"
  (cd ../terraform && terraform output -raw prometheus_instance)
  echo ""

  echo "[webserver]"
  (cd ../terraform && terraform output -raw web_instance_ip_0)
  echo ""
  (cd ../terraform && terraform output -raw web_instance_ip_1)
  echo ""

  echo "[monitoring:children]"
  echo "webserver"
  echo "prometheus"
  echo ""

  echo "[all:vars]"
  echo "ansible_user=ec2-user"
  echo "ansible_ssh_private_key_file=./keys/my-key.pem"
  echo "ansible_python_interpreter=/usr/bin/python3"
} >> inventory.ini

# Create vars file with MySQL host info
echo "mysql_host: $(cd ../terraform && terraform output -raw rds_address)" > roles/webapp-ec2-config/vars/main.yml

#!/bin/bash


# Clear or create the inventory file
> playbooks/inventory.ini

# Write groups and hosts with IPs from terraform output
{
  echo "[grafana]"
  terraform output -raw grafana_instance
  echo ""

  echo "[prometheus]"
  terraform output -raw prometheus_instance
  echo ""

  echo "[webserver]"
  terraform output -raw web_instance_ip_0
  terraform output -raw web_instance_ip_1
  echo ""

  echo "[monitoring:children]"
  echo "webserver"
  echo "prometheus"
  echo ""

  echo "[all:vars]"
  echo "ansible_user=ec2-user"
  echo "ansible_ssh_private_key_file=./keys/my-key.pem"
  echo "ansible_python_interpreter=/usr/bin/python3"
} >> playbooks/inventory.ini

# Create vars file with MySQL host info
echo "mysql_host: $(terraform output -raw rds_address)" > playbooks/roles/webapp-ec2-config/vars/main.yml

#!/bin/bash

# Get list of private IPs for EC2 instances tagged with Role=webserver
web_ips=$(aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=web0,web1" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text)

# Set the output path for the Prometheus config inside the role
PROMETHEUS_CONFIG_PATH="../playbooks/roles/prometheus/files/prometheus.yml"

# Start writing the Prometheus config
cat > "$PROMETHEUS_CONFIG_PATH" << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'prometheus-server'
          environment: 'monitoring'
EOF

# Add each webserver IP to the config
index=1
for ip in $web_ips; do
  cat >> "$PROMETHEUS_CONFIG_PATH" << EOF

      - targets: ['$ip:9100']
        labels:
          instance: 'web-server-$index'
          environment: 'production'
EOF
  ((index++))
done

echo "✅ Prometheus config generated with ${index-1} web server(s) at $PROMETHEUS_CONFIG_PATH"

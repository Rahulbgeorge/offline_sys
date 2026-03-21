#!/bin/bash
set -e

echo "====================================="
echo "Starting Prometheus & Node Exporter Setup"
echo "====================================="

# 1. Install Prometheus and Node Exporter
echo "--> Installing Prometheus and Node Exporter..."
apt-get update
apt-get install -y prometheus prometheus-node-exporter

# 2. Configure Prometheus
echo "--> Writing /etc/prometheus/prometheus.yml..."
cat << EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

remote_write:
  - url: "${PROMETHEUS_URL:-http://localhost:9090/api/v1/write}"
    basic_auth:
      username: "${PROMETHEUS_USERNAME:-admin}"
      password: "${PROMETHEUS_PASSWORD:-admin}"
EOF

# Restart Prometheus (if systemd is running)
# systemctl restart prometheus || service prometheus restart

echo "====================================="
echo "Prometheus setup complete. Scraping node_exporter & system metrics."
echo "====================================="

#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER STANDALONE UBUNTU 24.04 INSTALLER
# ==============================================================================
# This script installs the entire offline-server stack on a fresh Ubuntu 24.04.
# It includes: Nginx, Caddy (SSL), FastAPI (Gunicorn), SSH, Cloudflared, 
# Grafana Alloy, and Prometheus.
# ==============================================================================

echo "====================================="
echo "Starting Offline Server Installation"
echo "====================================="

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash install.sh)"
  exit 1
fi

# 2. Environment Variables Prompt
echo "--> Configuring environment..."
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi
if [ -f .env.git ]; then
    export $(grep -v '^#' .env.git | xargs)
fi

# Set Defaults
export HOST_DOMAIN=${HOST_DOMAIN:-"localhost"}
export CLOUDFLARED_TOKEN_NAME=${CLOUDFLARED_TOKEN_NAME:-"my_tunnel_token"}
export GIT_REPO_URL=${GIT_REPO_URL:-""}
export LOKI_URL=${LOKI_URL:-"http://localhost:3100/loki/api/v1/push"}
export LOKI_USERNAME=${LOKI_USERNAME:-"admin"}
export LOKI_PASSWORD=${LOKI_PASSWORD:-"admin"}
export LOKI_TENANT_ID=${LOKI_TENANT_ID:-"offline_tenant"}
export PROMETHEUS_URL=${PROMETHEUS_URL:-"http://localhost:9090/api/v1/write"}
export PROMETHEUS_USERNAME=${PROMETHEUS_USERNAME:-"admin"}
export PROMETHEUS_PASSWORD=${PROMETHEUS_PASSWORD:-"admin"}

# 3. Repository Setup (Caddy, Cloudflared, Grafana)
echo "--> Adding external repositories..."
apt-get update && apt-get install -y curl wget gnupg2 software-properties-common lsb-release apt-transport-https ca-certificates jq git

# Caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.list' | tee /etc/apt/sources.list.d/caddy-stable.list

# Cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-public-v2.gpg --yes
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list

# Grafana (Alloy)
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg || true
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# 4. Install All Packages
echo "--> Installing packages..."
apt-get update
apt-get install -y \
    nano vim sudo openssl python3 python3-pip python3-venv \
    systemd procps net-tools iproute2 dbus \
    nginx caddy ufw openssh-server cloudflared alloy \
    prometheus prometheus-node-exporter

# 5. Core Server Setup (from setup-server.sh)
echo "--> Setting up Python environment..."
mkdir -p /root/server
cd /root/server
python3 -m venv venv
source venv/bin/activate

if [ -n "$GIT_REPO_URL" ]; then
    echo "--> Cloning application repository..."
    if [ ! -d "app" ]; then
        git clone "$GIT_REPO_URL" app
    else
        cd app && git pull origin main || true
        cd ..
    fi
else
    echo "--> Creating dummy FastAPI application..."
    mkdir -p app
    cat << 'EOF' > /root/server/app/main.py
from fastapi import FastAPI
app = FastAPI()
@app.get("/")
def read_root():
    return {"status": "ok", "message": "Offline Server Running!"}
EOF
fi

echo "--> Installing Python dependencies..."
pip install fastapi uvicorn gunicorn httpx
if [ -f "/root/server/app/requirements.txt" ]; then
    pip install -r /root/server/app/requirements.txt
fi

echo "--> Creating FastAPI systemd service..."
cat << EOF > /etc/systemd/system/fastapi.service
[Unit]
Description=Gunicorn instance to serve FastAPI backend
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root/server/app
Environment="PATH=/root/server/venv/bin"
ExecStart=/bin/bash -c 'if [ -d /root/server/app/dummy-fastapi-server ]; then cd /root/server/app/dummy-fastapi-server; fi && /root/server/venv/bin/gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:8000'

[Install]
WantedBy=multi-user.target
EOF

echo "--> Configuring Nginx..."
cat << 'EOF' > /etc/nginx/sites-available/fastapi
upstream backend {
    server 127.0.0.1:8000;
}
server {
    listen 8080;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
ln -sf /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "--> Configuring Caddy..."
DOMAIN_LIST="localhost"
if [ "$HOST_DOMAIN" != "localhost" ]; then
    DOMAIN_LIST="$HOST_DOMAIN, localhost"
fi

cat << EOF > /etc/caddy/Caddyfile
$DOMAIN_LIST {
    reverse_proxy localhost:8080
    tls internal
}
EOF

# 6. SSH & Cloudflared Setup (from setup-ssh-tunnel.sh)
echo "--> Configuring SSH..."
mkdir -p /root/.ssh
if [ ! -f "/root/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "offline-server-key" -f /root/.ssh/id_ed25519 -N ""
    cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
fi
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

if [ "$CLOUDFLARED_TOKEN_NAME" != "my_tunnel_token" ]; then
    echo "--> Configuring Cloudflared service..."
    cat << EOF > /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare Tunnel Service
After=network.target

[Service]
Type=simple
Environment="CLOUDFLARED_TOKEN_NAME=$CLOUDFLARED_TOKEN_NAME"
ExecStart=/usr/bin/cloudflared tunnel run --token \$CLOUDFLARED_TOKEN_NAME
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
fi

# 7. Monitoring Setup (from setup-alloy.sh & setup-prometheus.sh)
echo "--> Configuring Grafana Alloy..."
mkdir -p /root/server/logs
cat << 'EOF' > /etc/alloy/config.alloy
local.file_match "server_logs" {
  path_targets = [{"__path__" = "/root/server/logs/*.log"}]
}
loki.source.file "local_files" {
  targets    = local.file_match.server_logs.targets
  forward_to = [loki.process.add_tenant_label.receiver]
}
loki.process "add_tenant_label" {
  forward_to = [loki.write.remote.receiver]
  stage.static_labels {
    values = {
      "tenant_id" = sys.env("LOKI_TENANT_ID"),
    }
  }
}
loki.write "remote" {
  endpoint {
    url = sys.env("LOKI_URL")
    tenant_id = sys.env("LOKI_TENANT_ID")
    basic_auth {
      username = sys.env("LOKI_USERNAME")
      password = sys.env("LOKI_PASSWORD")
    }
  }
}
EOF

echo "--> Configuring Prometheus..."
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
  - url: "$PROMETHEUS_URL"
    basic_auth:
      username: "$PROMETHEUS_USERNAME"
      password: "$PROMETHEUS_PASSWORD"
EOF

# 8. Start and Enable Services
echo "--> Enabling and starting services..."
systemctl daemon-reload
SERVICES=("ssh" "nginx" "caddy" "fastapi" "alloy" "prometheus" "prometheus-node-exporter")

for SVC in "${SERVICES[@]}"; do
    systemctl enable "$SVC"
    systemctl restart "$SVC"
done

if [ "$CLOUDFLARED_TOKEN_NAME" != "my_tunnel_token" ]; then
    systemctl enable cloudflared
    systemctl restart cloudflared
fi

echo "====================================="
echo "INSTALLATION COMPLETE!"
echo "Server is accessible via HTTPS on port 443."
echo "SSH access enabled via keys (no password)."
echo "Monitoring (Alloy/Prometheus) is active."
echo "====================================="

#!/bin/bash
set -e

# setup-ubuntu.sh
# This script installs the offline-server directly on Ubuntu 24.04.

echo "====================================="
# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (using sudo)."
  exit 1
fi

echo "--> Detected Ubuntu 24.04. Starting Installation..."
echo "====================================="

# 1. Update and install basic tools
echo "--> Installing dependencies and adding repositories..."
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git gnupg2 software-properties-common lsb-release apt-transport-https ca-certificates jq

# 2. Add Caddy Repository
echo "--> Adding Caddy repository..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || true
if [ ! -f /etc/apt/sources.list.d/caddy-stable.list ]; then
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.list' | tee /etc/apt/sources.list.d/caddy-stable.list
fi

# 3. Add Cloudflared Repository (if not already there)
echo "--> Adding Cloudflared repository..."
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-public-v2.gpg || true
if [ ! -f /etc/apt/sources.list.d/cloudflared.list ]; then
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
fi

# 4. Add Grafana Repository
echo "--> Adding Grafana repository..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg || true
if [ ! -f /etc/apt/sources.list.d/grafana.list ]; then
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
fi

# 5. Update and install all required packages
echo "--> Installing all server packages..."
apt-get update
# Combined package list from Dockerfile and scripts
apt-get install -y \
    nano vim sudo openssl python3 python3-pip python3-venv \
    systemd procps net-tools iproute2 dbus \
    nginx caddy ufw openssh-server cloudflared alloy \
    prometheus prometheus-node-exporter

# 6. Load environment variables
echo "--> Loading environment variables..."

# Check if .env files exist, if not, create them from examples if examples exist
if [ ! -f .env ] && [ -f .env.example ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
fi

if [ ! -f .env.git ] && [ -f .env.git.example ]; then
    echo "Creating .env.git from .env.git.example..."
    cp .env.git.example .env.git
fi

# Load them
if [ -f .env ]; then
    echo "Using existing .env file."
    # Filter out comments and blank lines
    export $(grep -v '^#' .env | xargs)
fi

if [ -f .env.git ]; then
    echo "Using existing .env.git file."
    export $(grep -v '^#' .env.git | xargs)
fi

# Set defaults if not provided
export GIT_REPO_URL=${GIT_REPO_URL:-""}
export HOST_DOMAIN=${HOST_DOMAIN:-"localhost"}
export CLOUDFLARED_TOKEN_NAME=${CLOUDFLARED_TOKEN_NAME:-"my_tunnel_token"}

if [ -z "$GIT_REPO_URL" ]; then
    echo "WARNING: GIT_REPO_URL not set in .env.git"
fi

# 7. Run individual setup scripts
echo "--> Running setup scripts..."

# Make scripts executable
chmod +x scripts/*.sh

# Run server setup (Nginx, Caddy, Python app)
./scripts/setup-server.sh

# Run SSH & Tunnel setup
./scripts/setup-ssh-tunnel.sh

# Run Monitoring setup
./scripts/setup-alloy.sh
./scripts/setup-prometheus.sh

# 8. Start and enable services
echo "--> Finalizing services..."
systemctl daemon-reload

SERVICES=("fastapi" "nginx" "caddy" "ssh" "alloy" "prometheus" "prometheus-node-exporter")

for SVC in "${SERVICES[@]}"; do
    echo "Checking service: $SVC"
    systemctl enable "$SVC" || true
    systemctl restart "$SVC" || true
done

# If cloudflared token is valid, start it
if [ "$CLOUDFLARED_TOKEN_NAME" != "my_tunnel_token" ]; then
    echo "Enabling Cloudflared service..."
    systemctl enable cloudflared || true
    systemctl restart cloudflared || true
fi

echo "====================================="
echo "Installation complete!"
echo "Your server should be running on HTTPS port 443."
echo "FastAPI is on port 8080 (internal proxy: 8000)."
echo "Nginx is on 8080."
echo "SSH is active on port 22."
echo "====================================="

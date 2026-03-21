#!/bin/bash
set -e

echo "====================================="
echo "Bootstrapping Container..."
echo "====================================="

# Ensure scripts are executable
chmod +x /scripts/*.sh

# Run all setup scripts
echo "--> Running setup-server.sh"
/scripts/setup-server.sh

echo "--> Running setup-ssh-tunnel.sh"
/scripts/setup-ssh-tunnel.sh

echo "--> Running setup-alloy.sh"
/scripts/setup-alloy.sh

echo "--> Running setup-prometheus.sh"
/scripts/setup-prometheus.sh

echo "====================================="
echo "Starting Background Services..."
echo "====================================="

# Start SSH
mkdir -p /run/sshd
/usr/sbin/sshd

# Start Gunicorn Backend
source /root/server/venv/bin/activate
cd /root/server/app
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:8000 --daemon
cd -

# Start Nginx
service nginx start

# Start Alloy
if command -v alloy >/dev/null 2>&1; then
    alloy run /etc/alloy/config.alloy > /root/server/logs/alloy.log 2>&1 &
fi

# Start Prometheus
if command -v prometheus >/dev/null 2>&1; then
    prometheus --config.file=/etc/prometheus/prometheus.yml > /root/server/logs/prometheus.log 2>&1 &
fi
if command -v prometheus-node-exporter >/dev/null 2>&1; then
    prometheus-node-exporter > /root/server/logs/node_exporter.log 2>&1 &
fi

# Start Cloudflared Tunnel (if token provided)
if [ -n "$CLOUDFLARED_TOKEN_NAME" ] && [ "$CLOUDFLARED_TOKEN_NAME" != "my_tunnel_token" ]; then
    echo "Starting Cloudflare Tunnel..."
    cloudflared tunnel run $CLOUDFLARED_TOKEN_NAME &
fi

echo "====================================="
echo "Starting Caddy in foreground (SSL reverse proxy)..."
echo "You can access the server at https://localhost:8000 or https://localhost"
echo "====================================="

caddy run --config /etc/caddy/Caddyfile

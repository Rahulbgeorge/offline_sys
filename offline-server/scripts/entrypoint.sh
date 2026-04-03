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

# echo "--> Running setup-alloy.sh"
# /scripts/setup-alloy.sh

# echo "--> Running setup-prometheus.sh"
# /scripts/setup-prometheus.sh

# 2. Preparation for systemd
echo "--> Enabling systemd services"
# Enable services that should start with the container
systemctl enable ssh
systemctl enable nginx
systemctl enable caddy
systemctl enable fastapi
systemctl enable cloudflared || true

echo "====================================="
echo "Handing over to systemd (PID 1)..."
echo "====================================="

# Use exec to replace the shell bash process (PID 1) with systemd.
exec /lib/systemd/systemd


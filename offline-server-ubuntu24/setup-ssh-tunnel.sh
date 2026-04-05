#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER SSH & CLOUDFLARE TUNNEL SETUP
# ==============================================================================
# This script handles the generation of SSH keys and the configuration
# of the Cloudflare tunnel as a systemd service.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash setup-ssh-tunnel.sh)"
  exit 1
fi

# Load variables from .env if present
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

TOKEN=${CLOUDFLARED_TOKEN:-"your_token_here"}

# 1. SSH Generation
echo "--> Configuring SSH..."
mkdir -p /root/.ssh
if [ -f "./public_key.pub" ]; then
    echo "--> Installing provided public key to authorized_keys..."
    cat ./public_key.pub >> /root/.ssh/authorized_keys
else
    echo "WARNING: public_key.pub not found, skipping manual key installation."
fi
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Secure SSH config
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# 2. Cloudflared configuration
if [ "$TOKEN" != "your_token_here" ] && [ -n "$TOKEN" ]; then
    echo "--> Configuring Cloudflared service..."
    cat << EOF > /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare Tunnel Service
After=network.target

[Service]
Type=simple
Environment="CLOUDFLARED_TOKEN=$TOKEN"
ExecStart=/usr/bin/cloudflared tunnel run --token \$CLOUDFLARED_TOKEN
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable cloudflared
    systemctl restart cloudflared
else
    echo "SKIPPING Cloudflared setup (token missing in .env)."
fi

systemctl enable ssh
systemctl restart ssh

echo "SSH and Tunnel configuration complete."

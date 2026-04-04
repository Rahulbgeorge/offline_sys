#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER BASIC SETUP (UBUNTU 24.04)
# ==============================================================================
# This script handles the installation of base packages and external repositories.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash setup-ubuntu-basic.sh)"
  exit 1
fi

echo "--> Updating system and installing base packages..."
apt-get update && apt-get upgrade -y
apt-get install -y curl wget gnupg2 software-properties-common lsb-release apt-transport-https ca-certificates jq git

# Repository Setup (Caddy, Cloudflared)
echo "--> Adding Caddy and Cloudflared repositories..."

# Caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.list' | tee /etc/apt/sources.list.d/caddy-stable.list

# Cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-public-v2.gpg --yes
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list

echo "--> Final package installation..."
apt-get update
apt-get install -y \
    nano vim sudo openssl python3 \
    procps net-tools iproute2 dbus \
    caddy openssh-server cloudflared

echo "Basic system setup complete."

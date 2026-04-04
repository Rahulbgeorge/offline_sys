#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER DOCKER SETUP (UBUNTU 24.04)
# ==============================================================================
# This script installs Docker Engine and Docker Compose.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash setup-docker.sh)"
  exit 1
fi

echo "--> Installing Docker Engine and Docker Compose..."

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

# Install Docker packages
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add 'ubuntu' user to docker group if it exists
if id "ubuntu" &>/dev/null; then
  usermod -aG docker ubuntu
fi

echo "Docker installation complete."

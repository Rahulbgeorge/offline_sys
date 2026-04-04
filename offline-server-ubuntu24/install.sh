#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER STANDALONE UBUNTU 24.04 (LIGHTWEIGHT)
# ==============================================================================
# This is the master script that calls each individual component.
# ==============================================================================

echo "====================================="
echo "Starting Offline Server Installation (Ubuntu 24.04)"
echo "====================================="

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash install.sh)"
  exit 1
fi

# 2. Environment Loader
if [ ! -f .env ]; then
    echo "Warning: .env file missing. Using defaults."
else
    export $(grep -v '^#' .env | xargs)
fi

# 3. Component Execution
bash setup-ubuntu-basic.sh
bash setup-docker.sh
bash setup-ssh-tunnel.sh
bash setup-caddy.sh
bash export-ssh-keys.sh

echo "====================================="
echo "INSTALLATION COMPLETE!"
echo "Your server is ready and SSH keys exported to /home/ubuntu/exportable."
echo "====================================="

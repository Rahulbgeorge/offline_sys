#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER SSH KEY EXPORTER
# ==============================================================================
# This script copies the generated SSH keys to /home/ubuntu/exportable 
# for easy retrieval by the user.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash export-ssh-keys.sh)"
  exit 1
fi

EX_PATH="/home/ubuntu/exportable"
echo "--> Creating export folder at $EX_PATH..."
mkdir -p "$EX_PATH"

# 1. Export Private Key if exists
if [ -f "/root/.ssh/id_ed25519" ]; then
    echo "--> Copying private SSH key to $EX_PATH"
    cp /root/.ssh/id_ed25519 "$EX_PATH/id_ed25519"
    cp /root/.ssh/id_ed25519.pub "$EX_PATH/id_ed25519.pub"
    chmod 600 "$EX_PATH/id_ed25519"
fi

# 2. Export Authorized Keys if exists
if [ -f "/root/.ssh/authorized_keys" ]; then
    echo "--> Copying authorized_keys to $EX_PATH"
    cp /root/.ssh/authorized_keys "$EX_PATH/authorized_keys"
fi

# 3. Final Permissions setup
if id "ubuntu" &>/dev/null; then
    chown -R ubuntu:ubuntu "$EX_PATH"
fi

echo "SSH key export task complete."

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

# Copy keys from root's .ssh directory
if [ -f "/root/.ssh/id_ed25519" ]; then
    echo "--> Copying SSH keys to $EX_PATH"
    cp /root/.ssh/id_ed25519 "$EX_PATH/id_ed25519"
    cp /root/.ssh/id_ed25519.pub "$EX_PATH/id_ed25519.pub"
    cp /root/.ssh/authorized_keys "$EX_PATH/authorized_keys"
    
    # Set permissions if 'ubuntu' user exists
    if id "ubuntu" &>/dev/null; then
        chown -R ubuntu:ubuntu "$EX_PATH"
    fi
    chmod 600 "$EX_PATH/id_ed25519"
    echo "Keys exported successfully."
else
    echo "ERROR: Root SSH keys not found in /root/.ssh/id_ed25519. Have they been generated yet?"
    exit 1
fi

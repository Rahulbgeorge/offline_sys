#!/bin/bash
set -e

echo "====================================="
echo "Starting SSH & Cloudflared Setup"
echo "====================================="

# 1. Setup OpenSSH Server
echo "--> Installing OpenSSH server..."
apt-get update
apt-get install -y openssh-server
mkdir -p /run/sshd

# 2. SSH Key Generation
echo "--> Generating SSH Keys for root access..."
mkdir -p /root/.ssh
if [ ! -f "/root/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "offline-server-key" -f /root/.ssh/id_ed25519 -N ""
else
    echo "SSH key already exists."
fi

echo "--> Authorizing new SSH key..."
cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chmod 600 /root/.ssh/id_ed25519

# 3. Disable password login
echo "--> Securing SSH by disabling password authentication..."
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Enable SSH service (if systemctl is available)
# systemctl enable ssh
# systemctl restart ssh || service ssh restart

# 4. Install Cloudflared
echo "--> Installing Cloudflared..."
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
apt-get update && apt-get install -y cloudflared

# 5. Connect Tunnel Config (Execution moved to entrypoint.sh)
echo "--> Configuring Cloudflared..."
if [ -n "$CLOUDFLARED_TOKEN_NAME" ] && [ "$CLOUDFLARED_TOKEN_NAME" != "my_tunnel_token" ]; then
    echo "Note: Cloudflare service tunnel will run from entrypoint.sh automatically based on the token."
else
    echo "CLOUDFLARED_TOKEN_NAME not found or is default. Tunnel won't auto-start."
fi

echo "====================================="
echo "SSH and Tunnel setup complete."
echo "Important: Note your private key from /root/.ssh/id_ed25519 to access this server remotely."
echo "====================================="

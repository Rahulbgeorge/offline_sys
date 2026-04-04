#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER CADDY SETUP
# ==============================================================================
# This script handles the configuration of Caddy as a web server.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash setup-caddy.sh)"
  exit 1
fi

DOMAIN=${HOST_DOMAIN:-"localhost"}

echo "--> Configuring Caddy with a minimal placeholder page..."
cat << EOF > /etc/caddy/Caddyfile
$DOMAIN {
    # Default landing page
    respond "Offline Server (Ubuntu 24.04 Ready)" 200
    tls internal
}
EOF

systemctl enable caddy
systemctl restart caddy

echo "Caddy setup complete."

#!/bin/bash
set -e

echo "====================================="
echo "Starting Grafana Alloy Setup"
echo "====================================="

# 1. Install Grafana Alloy
echo "--> Installing Grafana Alloy..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg || true
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y alloy

# Ensure logs directory exists so Alloy doesn't fail on startup
mkdir -p /root/server/logs
touch /root/server/logs/dummy.log

# 2. Create config.alloy
echo "--> Writing /etc/alloy/config.alloy..."
cat << 'EOF' > /etc/alloy/config.alloy
local.file_match "server_logs" {
  path_targets = [{"__path__" = "/root/server/logs/*.log"}]
}

loki.source.file "local_files" {
  targets    = local.file_match.server_logs.targets
  forward_to = [loki.write.remote.receiver]
}

loki.write "remote" {
  endpoint {
    url = sys.env("LOKI_URL")
    tenant_id = sys.env("LOKI_TENANT_ID")
    basic_auth {
      username = sys.env("LOKI_USERNAME")
      password = sys.env("LOKI_PASSWORD")
    }
  }
}
EOF

# Restart Alloy (if systemctl is running)
# systemctl restart alloy || service alloy restart

echo "====================================="
echo "Alloy setup complete. Logs from /root/server/logs/*.log will be forwarded."
echo "====================================="

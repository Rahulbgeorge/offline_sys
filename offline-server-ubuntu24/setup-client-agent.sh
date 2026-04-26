#!/bin/bash
set -e

# ==============================================================================
# OFFLINE-SERVER CLIENT-AGENT SETUP (UBUNTU 24.04)
# ==============================================================================
# This script installs the client-agent and configures it as a systemd service.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo bash setup-client-agent.sh)"
  exit 1
fi

# Load variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Get absolute path of the project root
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
AGENT_DIR="$PROJECT_ROOT/client-agent"
SERVICE_NAME="offline-agent"

echo "--> Setting up Client Agent in $AGENT_DIR..."

if [ ! -d "$AGENT_DIR" ]; then
    echo "Error: $AGENT_DIR not found!"
    exit 1
fi

cd "$AGENT_DIR"

# 1. Create Python Virtual Environment
echo "--> Creating Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# 2. Install dependencies
echo "--> Installing dependencies..."
pip install --upgrade pip
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    # Default dependencies if requirements.txt is missing
    pip install psutil requests pydantic
fi

# 3. Configure Supervisor
echo "--> Configuring Supervisor..."
SUPERVISOR_CONF="/etc/supervisor/conf.d/$SERVICE_NAME.conf"

# Clean up old systemd service if it exists to avoid conflicts
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "--> Migrating from systemd to supervisor: removing old service..."
    systemctl stop $SERVICE_NAME || true
    systemctl disable $SERVICE_NAME || true
    rm "/etc/systemd/system/$SERVICE_NAME.service"
    systemctl daemon-reload
fi

PYTHON_BIN="$AGENT_DIR/.venv/bin/python3"
MAIN_PY="$AGENT_DIR/main.py"
RUN_USER=$(logname || echo "ubuntu")

echo "--> Creating supervisor config for user: $RUN_USER"

# Build environment string for supervisor if AGENT_DOMAIN is set
ENV_STR=""
if [ -n "$AGENT_DOMAIN" ]; then
    ENV_STR="environment=AGENT_DOMAIN=\"$AGENT_DOMAIN\""
fi

cat > "$SUPERVISOR_CONF" <<EOF
[program:$SERVICE_NAME]
command=$PYTHON_BIN $MAIN_PY run --store --non-interactive
directory=$AGENT_DIR
user=$RUN_USER
autostart=true
autorestart=true
stderr_logfile=/var/log/$SERVICE_NAME.err.log
stdout_logfile=/var/log/$SERVICE_NAME.out.log
$ENV_STR
EOF

echo "--> Supervisor configuration created at $SUPERVISOR_CONF"

# Reload supervisor and start the service
# Ensure logs exist and have correct permissions
touch /var/log/$SERVICE_NAME.err.log /var/log/$SERVICE_NAME.out.log
chown $RUN_USER:$RUN_USER /var/log/$SERVICE_NAME.*.log

supervisorctl reread
supervisorctl update
supervisorctl restart $SERVICE_NAME

echo "--> $SERVICE_NAME started and managed by Supervisor."

echo "Client Agent setup complete."

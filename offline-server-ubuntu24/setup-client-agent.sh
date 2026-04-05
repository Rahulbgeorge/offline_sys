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

# 3. Configure systemd service
echo "--> Configuring systemd service..."
TEMPLATE_FILE="agent-metrics.service.template"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

if [ -f "$TEMPLATE_FILE" ]; then
    # Construct configuration for systemd
    PYTHON_BIN="$AGENT_DIR/.venv/bin/python3"
    MAIN_PY="$AGENT_DIR/main.py"
    RUN_USER=$(logname || echo "ubuntu")
    
    echo "--> Creating service file for user: $RUN_USER"

    # Use a temporary file for construction
    cp "$TEMPLATE_FILE" "$SERVICE_FILE.tmp"
    
    # Apply standard replacements
    sed -i "s|WorkingDirectory=.*|WorkingDirectory=$AGENT_DIR|" "$SERVICE_FILE.tmp"
    sed -i "s|ExecStart=.*|ExecStart=$PYTHON_BIN $MAIN_PY run --store|" "$SERVICE_FILE.tmp"
    sed -i "s|User=.*|User=$RUN_USER|" "$SERVICE_FILE.tmp"
    
    # Inject AGENT_DOMAIN if present
    if [ -n "$AGENT_DOMAIN" ]; then
        sed -i "/\[Service\]/a Environment=\"AGENT_DOMAIN=$AGENT_DOMAIN\"" "$SERVICE_FILE.tmp"
        echo "--> Injected AGENT_DOMAIN=$AGENT_DOMAIN into service file"
    fi

    mv "$SERVICE_FILE.tmp" "$SERVICE_FILE"
    echo "--> Systemd service file created at $SERVICE_FILE"
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME
    
    echo "--> $SERVICE_NAME started and enabled."
else
    echo "Error: $TEMPLATE_FILE not found in $AGENT_DIR"
    exit 1
fi

echo "Client Agent setup complete."

#!/bin/bash
set -e

echo "Starting Observability Stack Setup..."

# Copy the environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Copying .env.example to .env (Feel free to update this for your environment)..."
    cp .env.example .env
fi

# Ensure log and data directories exist
echo "Creating required directories..."
mkdir -p logs data/loki data/grafana

# Secure permissions for grafana data directory (Grafana commonly runs as UID 472)
chmod -R 777 data/ || true

echo "Starting docker compose in detached mode..."
docker compose up -d

echo "✅ Setup Complete!"
echo "You can view the Grafana Dashboards at http://localhost:3000"
echo "Dummy logs can be pushed to observability/logs/ to see Alloy auto-tail them."

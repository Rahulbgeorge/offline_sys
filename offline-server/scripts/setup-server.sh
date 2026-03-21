#!/bin/bash
set -e

echo "====================================="
echo "Starting Server Setup"
echo "====================================="

# 1. Basic Ubuntu Setup
echo "--> Updating packages..."
apt-get update && apt-get upgrade -y
apt-get install -y python3 python3-pip python3-venv git curl wget nginx caddy ufw

# 2. Setup Python & Environment
echo "--> Setting up server folder and Python virtual environment..."
mkdir -p /root/server
cd /root/server
python3 -m venv venv
source venv/bin/activate

# 3. Clone Repository
echo "--> Cloning repository..."
if [ -n "$GIT_REPO_URL" ]; then
    echo "Cloning $GIT_REPO_URL..."
    git clone "$GIT_REPO_URL" app
else
    echo "GIT_REPO_URL environment variable not found, creating dummy app layout"
    mkdir -p app
fi

# 4. Dummy FastAPI & Gunicorn setup
echo "--> Initializing FastAPI backend..."
cat << 'EOF' > /root/server/app/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Offline Server Running!"}
EOF

pip install fastapi uvicorn gunicorn httpx

echo "--> Creating Systemd Service for Gunicorn..."
cat << 'EOF' > /etc/systemd/system/fastapi.service
[Unit]
Description=Gunicorn instance to serve FastAPI backend
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root/server/app
Environment="PATH=/root/server/venv/bin"
# Binding to 127.0.0.1:8000 internally
ExecStart=/root/server/venv/bin/gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:8000

[Install]
WantedBy=multi-user.target
EOF

# In a realistic Ubuntu VM we would enable this
# systemctl enable --now fastapi

# 5. Setup Nginx (Load Balancing)
echo "--> Configuring Nginx for Load Balancing..."
cat << 'EOF' > /etc/nginx/sites-available/fastapi
upstream backend {
    # Load balancing endpoints
    server 127.0.0.1:8000;
    # Add more servers here to balance load across multiple replicas
    # server 127.0.0.1:8001;
}

server {
    listen 8080; # Nginx listens on 8080 (internal or proxied further by Caddy)

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
ln -sf /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
# systemctl restart nginx

# 6. Setup Caddy (SSL)
echo "--> Configuring Caddy Server (Local SSL proxy to Nginx)..."
cat << 'EOF' > /etc/caddy/Caddyfile
# Secure HTTPS reverse proxy to Nginx Load Balancer using Caddy's Local HTTPS
localhost, localhost:8000 {
    reverse_proxy localhost:8080
}
EOF
# systemctl restart caddy

echo "====================================="
echo "Server setup complete."
echo "Note: If running in Docker without systemd, you must manually start gunicorn, nginx, and caddy."
echo "====================================="

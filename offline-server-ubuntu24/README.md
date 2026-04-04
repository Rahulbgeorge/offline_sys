# Offline Server - Ubuntu 24.04 (Staging Ready)

This repository contains a lightweight, automated setup script for a fresh Ubuntu 24.04 installation. 
It installs only the essential components required for remote access and HTTPS tunneling, bypassing full stack components like observability (Grafana/Prometheus) and backend clusters (FastAPI/Nginx).

### Prerequisites
- Fresh Ubuntu 24.04 installation.
- Root or sudo privileges.
- A Cloudflared Tunnel token (obtainable from the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)).

---

### Step-by-Step Installation

1. **Prepare Environment Variables**
   Copy the example environment file and add your Cloudflared token:
   ```bash
   cp .env.example .env
   nano .env
   ```
   **Important**: Paste your `CLOUDFLARED_TOKEN` into the `.env` file. If this is missing, the tunnel service will not start correctly.

2. **Make the install script executable**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation script**
   ```bash
   sudo ./install.sh
   ```

---

### What this script does:
1. **Installs Essential Packages** (`setup-ubuntu-basic.sh`): Updates the system and installs `caddy`, `ssh`, and `cloudflared`.
2. **Setup Docker Engine** (`setup-docker.sh`): 
   - Installs Docker Engine, CLI, and the Docker Compose plugin.
   - Adds the 'ubuntu' user to the `docker` group for passwordless docker usage.
3. **Secures SSH & Tunnel** (`setup-ssh-tunnel.sh`): 
   - Generates Ed25519 SSH keys if they haven't been created yet.
   - Disables password authentication (key-based auth only).
   - Configures `cloudflared` as a persistent systemd service using your token.
4. **Web Server** (`setup-caddy.sh`):
   - Configures `Caddy` with a minimal placeholder landing page on your `HOST_DOMAIN`.
5. **Exports Credentials** (`export-ssh-keys.sh`): 
   - Creates a public export folder at `/home/ubuntu/exportable`.
   - Copies both the private and public keys there for easy retrieval.

---

### Folder Structure
- `offline-server-ubuntu24/`
  - `install.sh`: The master orchestration script.
  - `setup-ubuntu-basic.sh`: Basic package and repository setup.
  - `setup-docker.sh`: Full Docker Engine and Compose installation.
  - `setup-ssh-tunnel.sh`: SSH key generation and Cloudflared service configuration.
  - `setup-caddy.sh`: Caddy web server setup with minimal config.
  - `export-ssh-keys.sh`: Helper script to copy keys to `/home/ubuntu/exportable`.
  - `.env.example`: Template for environment variables.
  - `README.md`: This file.

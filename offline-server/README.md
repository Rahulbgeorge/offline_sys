# Offline Server Environment

This directory contains the necessary configs and scripts to provision a fully automated Ubuntu 24.04 environment serving an offline Python backend. It spins up a Docker container that mimics a bare-metal server deployment.

## Architecture & Services
The container leverages several moving parts to ensure high availability, security, and robust observability:
- **FastAPI / Python Application**: A backend served efficiently by `gunicorn` inside a Python virtual environment.
- **Nginx Load Balancer**: Proxies traffic internally and balances load across multiple backend runners.
- **Caddy (SSL Gateway)**: Sits at the edge, listening for HTTPS traffic and dynamically reverse-proxying it to Nginx.
- **OpenSSH Server**: Configured strictly with Ed25519 key-pair authentication (password login disabled).
- **Cloudflared Tunnel**: Provides external access to SSH safely without opening any firewall ports.
- **Grafana Alloy**: Deployed to scrape and forward application and system logs directly to your centralized Loki instance.
- **Prometheus & Node Exporter**: Scrapes internal application/host metrics and dispatches them via `remote_write` to a centralized Prometheus cluster.

---

## Deployment Guide◊

### 1. Set up your Environment Credentials

There are two required environment files you need to initialize. We provide templates for both.

```bash
# General config (Logs, Metrics, Cloudflare)
cp .env.example .env

# Git access config
cp .env.git.example .env.git
```

Open these files in your editor:
- **`.env`**: Populate your Loki/Prometheus URLs and basic-auth credentials. Add your Cloudflare Zero Trust Tunnel Token.
- **`.env.git`**: Populate your Git Host URL with a Personal Access Token (PAT). This dictates the repository the server will automatically clone and deploy on startup.

### 2. Boot the Server

To launch the environment in the background, run:

```bash
docker compose up -d --build
```

**Boot Process (`entrypoint.sh`)**:
1. It updates `apt` and installs all requisite binaries automatically.
2. It generates a fresh virtual environment and `git clone`'s your target code.
3. It installs the dummy FastAPI app, Nginx config, and Caddyfile.
4. It boots `sshd`, `nginx`, your backend web server, node exporter, Alloy, Prometheus, and Cloudflare in the background.
5. It runs Caddy in the foreground, establishing SSL locally.

> **Note**: Since this architecture bootstraps the database and dependencies from scratch via scripts, the initial container boot takes 2–4 minutes depending on network bandwidth. You can watch the progress via `docker compose logs -f`.

### 3. Access the Application

Once booted, the application relies on Caddy to provide instant Local HTTPS. Open your browser and navigate to:

- **HTTPS (Caddy SSL)**: `https://localhost:8443`
- **HTTP (Redirect)**: `http://localhost:8081` (Redirects to HTTPS)
- **Direct Nginx (Internal API)**: `http://localhost:8082`

> **Domain Support**: If you set `HOST_DOMAIN` in your `.env` (e.g., `sumangali.offlinesys.shop`), Caddy will also respond to that domain. To test locally, you can map this domain to `127.0.0.1` in your host's `/etc/hosts` file and access `https://sumangali.offlinesys.shop:8443`.

### 4. Remote Administration via SSH

The server auto-generates SSH keys to ensure absolute security, keeping the `id_ed25519` private key localized. To retrieve it and log in:

1. Copy the private key out of the container to your desktop:
   ```bash
   docker cp offline-ubuntu:/root/.ssh/id_ed25519 ./id_ed25519
   ```
2. Lock its permissions (SSH mandates this security standard):
   ```bash
   chmod 600 ./id_ed25519
   ```
3. Dial natively over the mapped Docker port:
   ```bash
   ssh -i ./id_ed25519 root@localhost -p 2222
   ```

*(If you initialized the Cloudflare tunnel in your `.env` file, you can also SSH over the active Zero Trust tunnel proxy command routing).*

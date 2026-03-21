# Cloud Server Observability Setup

This directory contains the central observability stack (Grafana, Loki, and Caddy) designed to be hosted on a public cloud server (e.g., AWS EC2, DigitalOcean, or an accessible homelab server).

This server receives logs securely from your distributed offline servers via the public internet.

## Getting Started

### 1. Prerequisites
- Docker and Docker Compose installed on your cloud server.
- Optional but recommended: A registered domain name pointing to the public IP of this server (for HTTPS).

### 2. Configure Credentials

First, copy the example environment file:
```bash
cp .env.example .env
```

The cloud server uses a secure **Caddy Reverse Proxy** to protect Loki from public access. You need to provide a hashed password to authorize inbound logs.

1. Decide on a strong password (e.g., `SuperSecretLogPassword123!`).
2. Generate its bcrypt hash using the Caddy container:
   ```bash
   docker compose run --rm caddy caddy hash-password --plaintext "SuperSecretLogPassword123!"
   ```
3. Open your `.env` file and replace the `LOKI_AUTH_HASH` with the generated hash. Also set a secure `GRAFANA_ADMIN_PASSWORD`.

### 3. Configure the Caddyfile (Optional Domains)

Open `Caddyfile`. By default, it listens on port `:8080`.
If you have a domain pointing to this server, replace `:8080` with your domain (e.g., `logs.yourcompany.com`). Caddy will automatically provision TLS (HTTPS) certificates for it!

### 4. Boot the Stack

Launch the cloud server components in the background:
```bash
docker compose up -d
```
This will start:
- **Caddy** (Reverse Proxy & Authentication Guard) on ports 80, 443, and 8080.
- **Grafana** (Visualization UI) on port 3000.
- **Loki** (Log Aggregation Database) accessible locally (but proxied safely by Caddy).

---

## Connecting the Offline Server to this Cloud Server

To make your `offline-server` stream its logs directly to this `cloud-server`, you must update the `.env` file **on the offline-server machine**.

In the `offline-server/.env` file, modify the Loki configuration block as follows:

```dotenv
# Loki Configuration for Grafana Alloy
# Point this to your cloud server's IP address (port 8080) or Domain Name
LOKI_URL=http://<YOUR_CLOUD_SERVER_IP>:8080/loki/api/v1/push
# If using a domain with HTTPS: LOKI_URL=https://logs.yourcompany.com/loki/api/v1/push

# Username must match the basic auth handle inside cloud-server/Caddyfile
LOKI_USERNAME=loki_shipper

# Password must be the PLAINTEXT password you used to generate the hash above!
LOKI_PASSWORD=SuperSecretLogPassword123!

# Distinguish this specific offline server's logs
LOKI_TENANT_ID=store_location_#1
```

Once the `.env` on the `offline-server` is updated naturally, boot or restart it:
```bash
docker compose down && docker compose up -d
```

### Viewing Logs
1. Navigate to Grafana on your cloud server: `http://<YOUR_CLOUD_SERVER_IP>:3000` (or your domain).
2. Log in using `admin` and the password defined in your `GRAFANA_ADMIN_PASSWORD` `.env` variable.
3. Use the Explore tab to search Loki for logs sent from your tenants!

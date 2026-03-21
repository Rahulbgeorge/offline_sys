# Production Setup: Cloud Server vs Local Tenant

## How does communication happen?
In production, your actual stores/tenants are distributed across the country and separated by the public internet. 
Communication happens **unidirectionally via HTTP/HTTPS** from the Tenant to the Cloud. 

1. **The Cloud Server** runs on a public IP or Cloud VPS (e.g., AWS EC2, DigitalOcean). It exposes an endpoints, e.g., `https://logs.yourcompany.com/loki/api/v1/push`.
2. **The Local Tenant** (Alloy) runs on the private store server. Because it pushes *outward* to the cloud, it easily bypasses the local strict firewalls and NATs (just like loading a website).

### How is it Secured?
Since Loki's ingestion endpoint is exposed to the internet, anyone could send fake logs to your system. To prevent this:
- We place a **Caddy Server** (Reverse Proxy) in front of Loki on the cloud server.
- Caddy enforces **TLS (HTTPS)** to encrypt the log data in transit.
- Caddy enforces **Basic Authentication**, verifying a Username and Password before letting the logs touch Loki.
- The Local Tenant (`config.alloy`) is configured with `basic_auth` to provide those credentials when securely transmitting the logs!

---

## Directory Breakdown

* **`cloud-server/`**: Deploy this tightly on your single centralized Cloud VPS. It contains Grafana, Loki, and Caddy.
* **`local-tenant/`**: Distribute this lightweight folder to your 100s of actual tenants, deploying it alongside their local FastAPI servers.

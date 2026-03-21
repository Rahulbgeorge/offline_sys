# Future Modifications and Scaling Guide

This guide details how to adapt the observability stack as the system scales and requirements grow.

## 1. Expanding the Edge to Remote Tenants
Currently, the `docker-compose.yml` runs a local Grafana Alloy instance for testing. For actual tenants out in the wild:
- Distribute the Grafana Alloy binary/Docker image to the tenant's system.
- Provide the tenant with the `config.alloy` file.
- Replace the local `LOKI_URL` in their `.env` with your public cloud endpoint (e.g., `https://logs.yourdomain.com/loki/api/v1/push`).
- Issue unique `TENANT_ID` values for each tenant to avoid log mingling.

## 2. Securing Loki for Production
By default, Loki accepts any incoming push request. For external edge agents publishing over the public internet, you must implement authentication.
- **Solution:** Place an NGINX or Caddy reverse proxy in front of Loki, and enforce Basic Authentication. Configure Grafana Alloy to pass the basic auth credentials.

## 3. High Availability (HA) Loki
If log volumes grow massively:
- Migrate from a single monolithic Loki instance to the "Simple Scalable Deployment" via Helm or Docker Swarm.
- Use an external object storage (AWS S3, Google GCS, or MinIO) instead of local filesystem storage, which allows true horizontally scalable readers and writers.

## 4. Alerting
While this dashboard visualizes errors, active alerting is critical.
- Use **Grafana Alerting**: Create rules inside Grafana checking `rate({tenant_id=~".+"} |~ "(?i)error"[1m]) > 5`.
- Grafana can fire webhooks, Slack messages, or emails notifying you before the tenant even notices.

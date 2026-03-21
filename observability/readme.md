# Multitenant Observability Stack (Loki + Grafana + Alloy)

Detailed instructions to run the multitenant observability system to aggregate, monitor, and trace logs from 100s of connected edge tenants.

## Overview
- **Loki:** Scalable, highly-available log aggregation system.
- **Grafana:** Visualizes the logs. A default "Tenant Logs" dashboard is pre-provisioned.
- **Grafana Alloy (Edge):** Runs at the tenant site, reads local logs, dynamically tags them with `tenant_id` from the environment, and forwards them to the central Loki URL.

## Quick Start
1. Edit variables in `.env.example` if needed, or stick to the defaults.
2. Run `./setup.sh`.
   - This copies `.env.example` to `.env`.
   - Creates the necessary directories (`logs`, `data`).
   - Starts `docker-compose up -d`.
3. Open Grafana at [http://localhost:3000](http://localhost:3000) (admin/admin).
4. Navigate to **Dashboards** -> **Multitenant Log Streamer**.

## Testing Dummy Logs
The local Alloy instance is configured to monitor `/var/log/tenant_logs/**/*.log` inside the container, mounted to the local `./logs` folder.
You can trace dummy logs by echoing data to it:
```bash
echo "ERROR: Tenant database connection failed" >> logs/sample.log
```
The logs will instantly surface in the Grafana dashboard under `tenant-001`.

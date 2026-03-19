# Create an observability stack on the system


## Problem Statement: I have a multitenant architecture, my ERP systems related to gold and accounting is deployed on local servers across the nation, with network partiotioning between the cloud an the local servers being a real thing.


## Solution: 

Grafana
Prometheus
Loki
Grafana Alloy (agent)
Node Exporter

this looks like an ideal stack based on my research.

- please do further breakdown, and i want a one click deployable solution for this.
- use docker for setting up the whole thing


- create a readme file on how to setup and give me docker yml files, 

- clearly mention pros and cons, and what are the edge cases with this solution

- also create a seperate explanation readment telling what is happening line by line, and possible solutions for future changes

- I am using Fastapi, python server, so tell give me a setup for the cloud and via fastapi how to setup the logs to flow in correctly

---

## Operations
**Starting an existing stopped stack:**
If you have already run `up` previously and the services were just stopped, you can quickly boot them again:
```bash
docker compose -f docker-compose.local.yml start
```

**Auto-starting on boot:**
As long as services in your `docker-compose.local.yml` possess the `restart: unless-stopped` directive, you do NOT have to run the command again on machine startup. Docker will automatically launch the containers.

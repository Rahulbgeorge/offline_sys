# Docker & Docker Compose — Command Reference

---

## Starting a Stack from a Compose File

```bash
# Basic start (foreground, see all logs)
docker compose -f docker-compose.cloud.yml up

# Start in background (detached mode) ← use this normally
docker compose -f docker-compose.cloud.yml up -d

# Start with a specific .env file
docker compose -f docker-compose.cloud.yml --env-file .env up -d

# Start only specific services from the file
docker compose -f docker-compose.cloud.yml up -d prometheus loki

# Start an existing, stopped stack (fast boot, no recreation)
docker compose -f docker-compose.cloud.yml start

# Note: If `restart: unless-stopped` is in your compose file, 
# you don't need to run anything on system reboot. Docker starts it automatically.
```

---

## Stopping a Stack

```bash
# Stop containers (keeps them + their data volumes)
docker compose -f docker-compose.cloud.yml stop

# Stop AND remove containers (data volumes are preserved)
docker compose -f docker-compose.cloud.yml down

# Stop AND remove containers + volumes (⚠️ deletes all stored data)
docker compose -f docker-compose.cloud.yml down -v

# Stop AND remove containers + images too
docker compose -f docker-compose.cloud.yml down --rmi all
```

> [!CAUTION]
> `down -v` permanently deletes all Prometheus metrics, Loki logs, and Grafana dashboards stored in Docker volumes.

---

## Restarting

```bash
# Restart all services
docker compose -f docker-compose.cloud.yml restart

# Restart one specific service
docker compose -f docker-compose.cloud.yml restart grafana
```

---

## When You Change the .env File

Environment variables are baked in at container start time — just editing `.env` does **nothing** to running containers.

```bash
# After editing .env, recreate the affected containers:
docker compose -f docker-compose.cloud.yml --env-file .env up -d

# Docker Compose automatically detects which containers need
# recreating (env changed) and restarts only those.
# Your volumes/data are NOT affected.
```

> [!IMPORTANT]
> Always pass `--env-file .env` if your file isn't named exactly `.env` in the same directory.

---

## When You Change a Config File (e.g. prometheus.yml, loki.yml)

Config files are mounted as volumes — the file on disk is live, but the service needs a reload or restart to pick up changes.

```bash
# Option 1: Hot reload (if the service supports it)
# Prometheus supports this:
curl -X POST http://localhost:9090/-/reload

# Option 2: Restart just that one service (no data loss)
docker compose -f docker-compose.cloud.yml restart prometheus

# Option 3: Full recreate of one service
docker compose -f docker-compose.cloud.yml up -d --force-recreate prometheus
```

---

## When You Change the docker-compose.yml Itself

```bash
# Just re-run up -d — Compose compares current vs desired state
# and only recreates containers whose definition changed
docker compose -f docker-compose.cloud.yml up -d
```

---

## Viewing Logs

```bash
# All services
docker compose -f docker-compose.cloud.yml logs

# Follow live logs
docker compose -f docker-compose.cloud.yml logs -f

# Specific service, last 50 lines
docker compose -f docker-compose.cloud.yml logs -f --tail=50 grafana

# Single container by name
docker logs -f grafana_test
```

---

## Status & Inspection

```bash
# See all running containers in the stack
docker compose -f docker-compose.cloud.yml ps

# See ALL containers on the system (running + stopped)
docker ps -a

# See resource usage (CPU, RAM, network)
docker stats

# Inspect everything about a container (JSON output)
docker inspect <container_id_or_name>

# Check which files have changed in a container's filesystem
docker diff <container_name>
```

---

## Volume Management (Exploring & Killing)

```bash
# List all volumes
docker volume ls

# Inspect volume details (Mountpoint, Driver, etc.)
docker volume inspect <volume_name>

# Remove a specific volume
docker volume rm <volume_name>

# Force remove all unused volumes
docker volume prune

# List volumes with a specific label (if used in compose)
docker volume ls -f "label=com.docker.compose.project=my_project"
```

---

## Image Management

```bash
# List all local images
docker image ls

# Remove an image
docker rmi <image_id>

# Force remove an image (if used by a stopped container)
docker rmi -f <image_id>

# Remove all dangling images (no tags)
docker image prune

# Remove ALL unused images
docker image prune -a
```

---

## Getting a Shell & Executing Commands

```bash
# Open interactive bash shell
docker exec -it <container_name> bash

# Open interactive sh shell (useful for Alpine-based images)
docker exec -it <container_name> sh

# Run a command as a specific user (e.g., root)
docker exec -u 0 -it <container_name> whoami

# Run a one-off command and exit
docker exec <container_name> ls -lah /etc

# Attach to the main process (useful if the app logs to stdout)
docker attach <container_name>
```

---

## Pulling Latest Images

```bash
# Pull latest versions of all images in the file
docker compose -f docker-compose.cloud.yml pull

# Then recreate containers with the new images
docker compose -f docker-compose.cloud.yml up -d
```

---

## Manual Container Control (Killing & Removing)

```bash
# Stop a container gracefully
docker stop <container_name>

# KILL a container immediately (SIGKILL)
docker kill <container_name>

# Remove a stopped container
docker rm <container_name>

# FORCE remove a running container (Stops it first)
docker rm -f <container_name>

# Pause/Unpause all processes within a container
docker pause <container_name>
docker unpause <container_name>
```

---

## Cleaning Up (The Nuclear Options)

```bash
# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes (⚠️ deletes data)
docker volume prune

# Remove unused networks
docker network prune

# The Nuclear Option: Remove EVERYTHING not in use
# (Stopped containers, unused networks, dangling images)
docker system prune

# The GLOBAL Nuclear Option: Remove ALL unused images and volumes too
docker system prune -a --volumes
```

> [!CAUTION]
> `docker system prune -a` will remove ALL unused images, containers, and networks. Run `docker ps -a` and `docker volume ls` first to check what's there.

---

## Quick Cheatsheet

| Goal | Command |
|---|---|
| Start stack (background) | `docker compose -f <file> up -d` |
| Stop stack (keep data) | `docker compose -f <file> down` |
| Stop stack (delete data) | `docker compose -f <file> down -v` |
| Restart one service | `docker compose -f <file> restart <service>` |
| Interactive Shell | `docker exec -it <container_name> bash` |
| Check Logs (Follow) | `docker logs -f <container_name>` |
| List Volumes | `docker volume ls` |
| Kill Container | `docker kill <container_name>` |
| Force Remove Image | `docker rmi -f <image_id>` |
| Full Cleanup | `docker system prune -a --volumes` |

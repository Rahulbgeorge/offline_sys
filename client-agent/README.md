# Offline System Metrics Agent (offline-sys2)

A lightweight system metrics collection agent designed for multi-tenant architectures, with local persistence (WAL) and background execution capabilities.

## Features

- **Rich Metrics**: Collects CPU (avg, per-core, load, temp), RAM, Disk (partitions, SMART health), and Network usage.
- **Local Persistence**: Stores metrics in a local SQLite database with Write-Ahead Logging (WAL) enabled for performance and reliability during network partitions.
- **Data Exporter Abstraction**: Decoupled architecture allowing for multiple output targets (Console, JSON, or future Server exporters).
- **Professional CLI**: Command-line interface with support for background daemonization and status reporting.
- **One-Click Setup**: Automated environment setup with a single script.

## Getting Started

### 1. Installation

Clone the repository and run the setup script:

```bash
bash setup.sh
```

This will create a virtual environment and install all necessary dependencies (`psutil`, `pydantic`).

### 2. Using the CLI

The agent is managed through `client-agent/main.py`.

#### Start the Agent in Background
```bash
client-agent/.venv/bin/python3 client-agent/main.py start --store
```
*The `--store` flag ensures metrics are persisted to the local SQLite database (`metrics.db`).*

#### Check Status
```bash
client-agent/.venv/bin/python3 client-agent/main.py status
```

#### Stop the Agent
```bash
client-agent/.venv/bin/python3 client-agent/main.py stop
```

#### Run in Foreground (Debug Mode)
```bash
client-agent/.venv/bin/python3 client-agent/main.py run --store
```

#### View Summary Metrics Only
```bash
client-agent/.venv/bin/python3 client-agent/main.py run --summary
```

## Available Commands

| Command | Description |
|---------|-------------|
| `run`   | Run the agent in the foreground. |
| `start` | Start the agent in the background (daemon mode). |
| `stop`  | Gracefully stop the background agent. |
| `status`| Check if the agent is currently running. |
| `config`| View current default configuration. |

## CLI Options

- `--store`: Enable local persistence (SQLite WAL).
- `--interval <sec>`: Set the collection interval (default: 60s).
- `--tenant-id <id>`: Set the source tenant identifier.
- `--no-json`: Output metrics in plain dictionary format instead of JSON.
- `--summary`: Output only lean summary metrics.

## Components

- `metrics.py`: Core logic for hardware and system metrics collection.
- `storage.py`: SQLite WAL implementation for local data persistence.
- `exporters.py`: Abstract base class and concrete implementations for data output.
- `agent_service.py`: Cross-platform background process and PID management.
- `main.py`: CLI entry point and agent orchestration.

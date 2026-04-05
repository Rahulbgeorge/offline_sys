from abc import ABC, abstractmethod
import json
import requests
from metrics import SystemMetrics

class BaseExporter(ABC):
    @abstractmethod
    def initialize(self):
        """Initialize the exporter (e.g., open connections, setup files)."""
        pass

    @abstractmethod
    def export(self, data: dict):
        """Export the metrics data."""
        pass

class ConsoleExporter(BaseExporter):
    def __init__(self, as_json: bool = True, indent: int = 4):
        self.as_json = as_json
        self.indent = indent

    def initialize(self):
        # Console exporter doesn't need specific initialization
        pass

    def export(self, data: dict):
        """Prints metrics to stdout."""
        if self.as_json:
            print(json.dumps(data, indent=self.indent))
        else:
            print(data)

class ApiExporter(BaseExporter):
    def __init__(self, api_url: str, api_key: str, api_password: str = None):
        self.api_url = api_url
        self.api_key = api_key
        self.api_password = api_password

    def initialize(self):
        # Check connectivity with /status/
        try:
            status_url = self.api_url.replace('/metrics/', '/status/')
            requests.get(status_url, timeout=5)
        except Exception as e:
            print(f"[!] Warning: Could not connect to API at {self.api_url}: {e}")

    def export(self, data: dict):
        """Maps SystemMetrics to a list of MetricRecords and sends to API."""
        from datetime import datetime, timezone
        ts = datetime.now(timezone.utc).isoformat()
        
        cpu_util = data.get("cpu", {}).get("per_core_utilization", [])
        cpu_val = sum(cpu_util) / len(cpu_util) if cpu_util else data.get("cpu", {}).get("load_avg", {}).get("1m", 0) * 10
        
        payload = [
            {"metric_type": "cpu_usage", "value": round(cpu_val, 1), "timestamp": ts},
            {"metric_type": "ram_usage", "value": data.get("ram", {}).get("percentage", 0), "timestamp": ts},
            {"metric_type": "disk_usage", "value": max([p["percentage"] for p in data.get("disk", {}).get("partitions", [])]) if data.get("disk", {}).get("partitions") else 0, "timestamp": ts},
            {"metric_type": "network_traffic", "value": sum([i["bytes_sent"] + i["bytes_recv"] for i in data.get("network", {}).values()]) / 1024 / 1024, "timestamp": ts}
        ]
        
        try:
            headers = {
                "x-api-key": self.api_key,
                "x-api-password": self.api_password if self.api_password else ""
            }
            response = requests.post(self.api_url, json=payload, headers=headers, timeout=10)
            if response.status_code != 201:
                print(f"[!] API Error ({response.status_code}): {response.text}")
        except Exception as e:
            print(f"[!] Connection Error: {e}")

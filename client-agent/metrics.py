import psutil
import os
import json
import subprocess
import platform
from typing import Dict, List, Any, Optional
from pydantic import BaseModel, Field

# --- Pydantic Models for Structured Data ---

class CPUCoreMetrics(BaseModel):
    utilization: float

class CPULoadAvg(BaseModel):
    one_min: float = Field(alias="1m")
    five_min: float = Field(alias="5m")
    fifteen_min: float = Field(alias="15m")

    class Config:
        populate_by_name = True

class CPUMetrics(BaseModel):
    load_avg: CPULoadAvg
    per_core_utilization: List[float]
    temperature: Dict[str, Any] = {} # Can contain lists of sensors or platform-specific info

class RAMMetrics(BaseModel):
    total: int
    used: int
    available: int
    percentage: float

class DiskPartitionMetrics(BaseModel):
    device: str
    mountpoint: str
    fstype: str
    total: int
    used: int
    free: int
    percentage: float
    smart_status: Optional[str] = None # Added for T1.2

class DiskMetrics(BaseModel):
    partitions: List[DiskPartitionMetrics]
    health_summary: str = "Basic metrics available."

class NetworkInterfaceMetrics(BaseModel):
    bytes_sent: int
    bytes_recv: int
    packets_sent: int
    packets_recv: int
    errin: int
    errout: int
    dropin: int
    dropout: int

class SystemMetrics(BaseModel):
    cpu: CPUMetrics
    ram: RAMMetrics
    disk: DiskMetrics
    network: Dict[str, NetworkInterfaceMetrics]

class SummaryMetrics(BaseModel):
    cpu_usage_avg: float
    ram_usage_pct: float
    disk_usage_pct_max: float
    net_sent_total: int
    net_recv_total: int
    system_health: str = "OK"

# --- Helper Functions for Advanced Metrics ---

def get_mac_smart_status() -> Dict[str, str]:
    """Get SMART status for Mac disks using system_profiler."""
    try:
        result = subprocess.run(["system_profiler", "SPStorageDataType", "-json"], capture_output=True, text=True)
        if result.returncode == 0:
            data = json.loads(result.stdout)
            status_map = {}
            for item in data.get("SPStorageDataType", []):
                bsd_name = item.get("bsd_name")
                smart_status = item.get("physical_drive", {}).get("smart_status")
                if bsd_name and smart_status:
                    status_map[f"/dev/{bsd_name}"] = smart_status
            return status_map
    except Exception:
        pass
    return {}

def get_linux_smart_status() -> Dict[str, str]:
    """Get SMART status for Linux disks using smartctl (if available)."""
    # This is a placeholder for Linux targets
    return {}

def get_gpu_info() -> Dict[str, Any]:
    """Get GPU info where available."""
    gpu_info = {}
    if platform.system() == "Darwin":
        try:
            result = subprocess.run(["system_profiler", "SPDisplaysDataType", "-json"], capture_output=True, text=True)
            if result.returncode == 0:
                data = json.loads(result.stdout)
                for item in data.get("SPDisplaysDataType", []):
                    gpu_info[item.get("_name", "Unknown")] = {
                        "vram": item.get("spdisplays_vram"),
                        "cores": item.get("sppci_cores")
                    }
        except Exception:
            pass
    return gpu_info

# --- Metrics Collection Logic ---

def get_cpu_metrics() -> CPUMetrics:
    """Collect CPU metrics including temperature."""
    load_avg = os.getloadavg()
    cpu_percent_per_core = psutil.cpu_percent(interval=0.1, percpu=True)
    
    # Try multiple ways to get temperature
    temperatures = {}
    
    # 1. psutil (Linux-specific mostly)
    if hasattr(psutil, "sensors_temperatures"):
        try:
            temps = psutil.sensors_temperatures()
            for name, entries in temps.items():
                temperatures[name] = [{"label": e.label, "current": e.current} for e in entries]
        except Exception:
            pass
            
    # 2. GPU Info (Mac/Linux)
    gpu_info = get_gpu_info()
    if gpu_info:
        temperatures["GPU"] = gpu_info

    return CPUMetrics(
        load_avg=CPULoadAvg(**{"1m": load_avg[0], "5m": load_avg[1], "15m": load_avg[2]}),
        per_core_utilization=cpu_percent_per_core,
        temperature=temperatures
    )

def get_ram_metrics() -> RAMMetrics:
    """Collect RAM metrics."""
    virtual_mem = psutil.virtual_memory()
    return RAMMetrics(
        total=virtual_mem.total,
        used=virtual_mem.used,
        available=virtual_mem.available,
        percentage=virtual_mem.percent
    )

def get_disk_metrics() -> DiskMetrics:
    """Collect Disk metrics including SMART health."""
    smart_map = {}
    if platform.system() == "Darwin":
        smart_map = get_mac_smart_status()
    elif platform.system() == "Linux":
        smart_map = get_linux_smart_status()

    disk_partitions = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            disk_partitions.append(DiskPartitionMetrics(
                device=partition.device,
                mountpoint=partition.mountpoint,
                fstype=partition.fstype,
                total=usage.total,
                used=usage.used,
                free=usage.free,
                percentage=usage.percent,
                smart_status=smart_map.get(partition.device, "Unknown")
            ))
        except PermissionError:
            continue
            
    health_summary = "Healthy" if all(p.smart_status in ["Verified", "OK", "Unknown"] for p in disk_partitions) else "Warning"
    
    return DiskMetrics(
        partitions=disk_partitions,
        health_summary=health_summary
    )

def get_network_metrics() -> Dict[str, NetworkInterfaceMetrics]:
    """Collect Network metrics."""
    net_io = psutil.net_io_counters(pernic=True)
    return {
        interface: NetworkInterfaceMetrics(
            bytes_sent=stats.bytes_sent,
            bytes_recv=stats.bytes_recv,
            packets_sent=stats.packets_sent,
            packets_recv=stats.packets_recv,
            errin=stats.errin,
            errout=stats.errout,
            dropin=stats.dropin,
            dropout=stats.dropout
        ) for interface, stats in net_io.items()
    }

def collect_all_metrics() -> SystemMetrics:
    """Collect all foundational system metrics."""
    return SystemMetrics(
        cpu=get_cpu_metrics(),
        ram=get_ram_metrics(),
        disk=get_disk_metrics(),
        network=get_network_metrics()
    )

def get_summary_metrics() -> SummaryMetrics:
    """Collect only summary metrics."""
    cpu_avg = psutil.cpu_percent(interval=0.1)
    ram = psutil.virtual_memory()
    disk = get_disk_metrics()
    net_totals = psutil.net_io_counters()
    
    max_disk_pct = max([p.percentage for p in disk.partitions]) if disk.partitions else 0.0
    
    return SummaryMetrics(
        cpu_usage_avg=cpu_avg,
        ram_usage_pct=ram.percent,
        disk_usage_pct_max=max_disk_pct,
        net_sent_total=net_totals.bytes_sent,
        net_recv_total=net_totals.bytes_recv,
        system_health=disk.health_summary
    )

if __name__ == "__main__":
    print("--- Summary Metrics ---")
    print(get_summary_metrics().model_dump_json(indent=4))

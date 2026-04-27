import os
import argparse
import json
import time
import sys
from metrics import collect_all_metrics, get_summary_metrics
from storage import MetricsStorage
from exporters import ConsoleExporter, ApiExporter
from config_manager import ConfigManager

from agent_service import start_daemon, stop_daemon, get_status, PID_FILE

def add_shared_args(parser):
    parser.add_argument("--no-json", action="store_false", dest="json", help="Don't output metrics in JSON format", default=True)
    parser.add_argument("--summary", action="store_true", help="Output only summary metrics", default=False)
    parser.add_argument("--store", action="store_true", help="Store metrics to local SQLite database", default=False)
    parser.add_argument("--interval", type=int, help="Collection interval in seconds (default 60)", default=60)
    parser.add_argument("--tenant-id", type=str, help="Source tenant identifier", default="default-tenant")
    parser.add_argument("--api-url", type=str, help="Server API URL (e.g. http://localhost:8000/api/v1/metrics/)", default="http://127.0.0.1:8000/api/v1/metrics/")
    parser.add_argument("--api-key", type=str, help="Tenant API Key", default="test-key-123")
    parser.add_argument("--non-interactive", action="store_true", help="Skip setup wizard if config is missing", default=False)

def run_setup():
    print("--- SysWatch Agent Setup ---")
    url = input("Enter Server API URL [http://127.0.0.1:8000/api/v1/metrics/]: ") or "http://127.0.0.1:8000/api/v1/metrics/"
    api_key = input("Enter API Key: ")
    password = input("Enter API Password: ")
    interval = input("Enter Collection Interval (seconds) [60]: ") or "60"
    tenant_id = input("Enter Tenant ID [default-tenant]: ") or "default-tenant"

    config = ConfigManager()
    config.save_config(url, api_key, password, int(interval), tenant_id)
    return config.load_config()

def run_agent(args):
    config_mgr = ConfigManager()
    config = config_mgr.load_config()

    # If no config and no interactive flags and no env domain, trigger setup
    # Skip if --non-interactive is passed
    env_domain = os.getenv('AGENT_DOMAIN')
    default_url = "http://127.0.0.1:8000/api/v1/metrics/"
    
    if not config and args.api_url == default_url and not env_domain and not args.non_interactive:
        config = run_setup()

    # Use config as base, but environment or args can override
    if env_domain:
        if not env_domain.startswith("http"):
            api_url = f"https://{env_domain}/api/v1/metrics/"
        else:
            api_url = f"{env_domain}/api/v1/metrics/"
        print(f"[*] Using AGENT_DOMAIN from environment: {env_domain} -> {api_url}")
    else:
        api_url = args.api_url if args.api_url != default_url else config.get('api_url', args.api_url)
    
    # Priority: Command Line Args > Environment Variables > Config File > Hardcoded Defaults
    api_key = args.api_key if args.api_key != "test-key-123" else (os.getenv('AGENT_API_KEY') or config.get('api_key', args.api_key))
    interval = args.interval if args.interval != 60 else int(os.getenv('AGENT_INTERVAL') or config.get('interval', 60))
    tenant_id = args.tenant_id if args.tenant_id != "default-tenant" else (os.getenv('AGENT_TENANT_ID') or config.get('tenant_id', "default-tenant"))
    api_password = os.getenv('AGENT_API_PASSWORD') or config.get('api_password')

    # Initialize Storage
    storage = None
    if args.store:
        storage = MetricsStorage()
        print(f"[*] Local persistence enabled. Storing to metrics.db")

    # Initialize Exporters
    exporters = []
    exporters.append(ConsoleExporter(as_json=args.json))
    
    if api_url and api_key:
        exporters.append(ApiExporter(api_url=api_url, api_key=api_key, api_password=api_password))
    
    for exporter in exporters:
        exporter.initialize()

    try:
        while True:
            if args.summary:
                metrics = get_summary_metrics()
            else:
                metrics = collect_all_metrics()
            
            # 1. Local Persistence (WAL)
            if args.store:
                storage.append_metrics(metrics, tenant_id=args.tenant_id)
                storage.prune_old_data(max_age_hours=24)
            
            # 2. Exporters
            for exporter in exporters:
                exporter.export(metrics.model_dump())
            
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\n[*] Stopping agent...")

def main():
    parser = argparse.ArgumentParser(description="System Metrics Collection Agent")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # 'run' command
    run_parser = subparsers.add_parser("run", help="Run agent in foreground")
    add_shared_args(run_parser)

    # 'start' command
    start_parser = subparsers.add_parser("start", help="Start agent in background")
    add_shared_args(start_parser)

    # 'stop' command
    subparsers.add_parser("stop", help="Stop background agent")

    # 'status' command
    subparsers.add_parser("status", help="Check agent status")

    # 'setup' command
    subparsers.add_parser("setup", help="Run interactive configuration wizard")

    # 'config' command
    subparsers.add_parser("config", help="View configuration settings")
    add_shared_args(subparsers.add_parser("dummy_config")) # needed to reuse add_shared_args logic if we want to show defaults

    args = parser.parse_args()

    if args.command == "run" or args.command is None:
        if args.command is None:
            # Default to run if no command provided (for backward compatibility)
            # but we need to parse args again or just call run_agent with default args
            # Actually, let's enforce subcommands for "professional" feel
            parser.print_help()
            return
        run_agent(args)
    elif args.command == "start":
        # We need to pass the arguments that were intended for the daemon
        daemon_args = []
        if not args.json: daemon_args.append("--no-json")
        if args.summary: daemon_args.append("--summary")
        if args.store: daemon_args.append("--store")
        daemon_args.extend(["--interval", str(args.interval)])
        daemon_args.extend(["--tenant-id", args.tenant_id])
        
        start_daemon(sys.executable, __file__, daemon_args)
    elif args.command == "stop":
        stop_daemon()
    elif args.command == "status":
        get_status()
    elif args.command == "setup":
        run_setup()
    elif args.command == "config":
        config_mgr = ConfigManager()
        config = config_mgr.load_config()
        print(f"--- Configuration (from {config_mgr.get_path()}) ---")
        if config:
            for k, v in config.items():
                if 'password' in k:
                    print(f"{k}: {'*' * 8}")
                else:
                    print(f"{k}: {v}")
        else:
            print("No configuration file found. Run 'setup' to create one.")

if __name__ == "__main__":
    main()

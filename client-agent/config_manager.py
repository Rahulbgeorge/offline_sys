import os
import configparser
from typing import Optional, Dict

CONFIG_DIR = "/etc/offline-sync-cli"
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.conf")

class ConfigManager:
    def __init__(self, config_path: str = CONFIG_FILE):
        self.config_path = config_path
        self.config = configparser.ConfigParser()

    def exists(self) -> bool:
        return os.path.exists(self.config_path)

    def save_config(self, url: str, api_key: str, password: str, interval: int, tenant_id: str = "default-tenant"):
        """Saves configuration to the config file."""
        if not os.path.exists(CONFIG_DIR):
            try:
                os.makedirs(CONFIG_DIR, exist_ok=True)
            except PermissionError:
                # Fallback to local directory if /etc is blocked
                local_dir = os.path.expanduser("~/.offline-sync-cli")
                os.makedirs(local_dir, exist_ok=True)
                self.config_path = os.path.join(local_dir, "config.conf")
                print(f"[!] Permission denied for {CONFIG_DIR}. Falling back to {self.config_path}")

        self.config['AGENT'] = {
            'api_url': url,
            'api_key': api_key,
            'api_password': password,
            'interval': str(interval),
            'tenant_id': tenant_id
        }

        with open(self.config_path, 'w') as f:
            self.config.write(f)
        print(f"[*] Configuration saved to {self.config_path}")

    def load_config(self) -> Dict[str, str]:
        """Loads configuration from the config file."""
        # Try /etc first, then ~/.offline-sync-cli
        paths = [CONFIG_FILE, os.path.expanduser("~/.offline-sync-cli/config.conf")]
        
        for path in paths:
            if os.path.exists(path):
                self.config.read(path)
                if 'AGENT' in self.config:
                    return dict(self.config['AGENT'])
        return {}

    def get_path(self) -> str:
        return self.config_path

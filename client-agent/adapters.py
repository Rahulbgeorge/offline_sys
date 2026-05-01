import socket
import subprocess
from typing import List, Dict, Optional

class NetworkAdapter:
    @staticmethod
    def get_local_ip() -> str:
        """Fetch the primary local IP address."""
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            # Doesn't even have to be reachable
            s.connect(('10.255.255.255', 1))
            ip = s.getsockname()[0]
        except Exception:
            ip = '127.0.0.1'
        finally:
            s.close()
        return ip

class SupervisorAdapter:
    @staticmethod
    def get_services() -> List[Dict[str, str]]:
        """Fetch services running under supervisorctl."""
        services = []
        try:
            # Run supervisorctl status
            result = subprocess.run(['supervisorctl', 'status'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if not line.strip():
                        continue
                    parts = line.split()
                    if len(parts) >= 2:
                        name = parts[0]
                        status = parts[1]
                        details = ' '.join(parts[2:]) if len(parts) > 2 else ''
                        services.append({
                            'name': name,
                            'status': status,
                            'details': details
                        })
        except Exception:
            pass
        return services

class LastLoginAdapter:
    def __init__(self):
        self._last_known_login = None

    def get_last_login(self) -> Optional[Dict[str, str]]:
        """Fetch the last login info, return only if changed."""
        try:
            result = subprocess.run(['last', '-n', '1'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                # 'last' sometimes outputs wtmp begins on the last line, we ignore that
                if lines and lines[0].strip() and not lines[0].startswith("wtmp begins"):
                    current_login = lines[0].strip()
                    if current_login != self._last_known_login:
                        self._last_known_login = current_login
                        parts = current_login.split()
                        user = parts[0] if len(parts) > 0 else 'unknown'
                        return {
                            'raw_login_string': current_login,
                            'user': user
                        }
        except Exception:
            pass
        return None

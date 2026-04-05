import os
import signal
import subprocess
import sys
import time

PID_FILE = os.path.join(os.path.dirname(__file__), "agent.pid")

def get_pid():
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                return int(f.read().strip())
        except (ValueError, IOError):
            return None
    return None

def is_running():
    pid = get_pid()
    if pid:
        try:
            os.kill(pid, 0)
            return True
        except OSError:
            return False
    return False

def start_daemon(python_path, main_script, args):
    if is_running():
        print(f"[!] Agent is already running (PID: {get_pid()})")
        return

    # Construct the command
    cmd = [python_path, main_script, "run"] + args
    
    # Open log files
    log_file = open(os.path.join(os.path.dirname(__file__), "agent.log"), "a")
    
    # Start the process in the background
    process = subprocess.Popen(
        cmd,
        stdout=log_file,
        stderr=subprocess.STDOUT,
        preexec_fn=os.setpgrp if os.name != "nt" else None,
        start_new_session=True
    )
    
    with open(PID_FILE, "w") as f:
        f.write(str(process.pid))
    
    print(f"[*] Agent started in background (PID: {process.pid})")

def stop_daemon():
    pid = get_pid()
    if not pid or not is_running():
        print("[!] Agent is not running.")
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        return

    print(f"[*] Stopping agent (PID: {pid})...")
    try:
        os.kill(pid, signal.SIGTERM)
        # Wait a bit for it to stop
        for _ in range(5):
            if not is_running():
                break
            time.sleep(1)
        
        if is_running():
            print("[!] Agent did not stop, forcing...")
            os.kill(pid, signal.SIGKILL)
            
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        print("[*] Agent stopped.")
    except Exception as e:
        print(f"[!] Error stopping agent: {e}")

def get_status():
    if is_running():
        print(f"[*] Agent is RUNNING (PID: {get_pid()})")
    else:
        print("[*] Agent is STOPPED")

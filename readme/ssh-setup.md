# SSH Key Setup

Guide for generating SSH keys and configuring SSH access, including extracting keys from Docker containers.


`store_name=sumangali`
---

## 1. Generate SSH Key

Run this on the **server or inside a Docker container**:

```bash
ssh-keygen -t ed25519 -C "container-key" -f /root/.ssh/id_ed25519 -N ""
```

**Flags:**
- `-t ed25519` → key type (recommended over RSA)
- `-C` → label/comment for the key
- `-f` → output file path
- `-N ""` → no passphrase (suitable for automation)

This creates:
- `/root/.ssh/id_ed25519` — **private key** (keep secret, never share)
- `/root/.ssh/id_ed25519.pub` — **public key** (safe to share)

---

## 2. Authorize the Key for Login

Inside the server/container, add the public key to `authorized_keys`:

```bash
cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
```

---

## 3. Extract Keys from Docker Container

Copy keys from the container to your **local machine**:

```bash
# Copy private key
docker cp <container_name>:/root/.ssh/id_ed25519 ./id_ed25519

# Copy public key
docker cp <container_name>:/root/.ssh/id_ed25519.pub ./id_ed25519.pub

```

Fix permissions on your local machine (SSH refuses keys that are too permissive):

```bash
chmod 600 ./id_ed25519

```

# shortcut summary
```
# shortcut
docker cp offline-ubuntu:/root/.ssh/id_ed25519 ./$store_name

docker cp offline-ubuntu:/root/.ssh/id_ed25519.pub ./$store_name.pub

chmod 600 ./$store_name
```


---

## 4. SSH into the Container from Local Machine

```bash
ssh -i ./id_ed25519 root@<host> -p <port>
```

> If using Docker port mapping (e.g., `-p 2222:22`), use `-p 2222`.

**Example:**

```bash
ssh -i ./id_ed25519 root@localhost -p 2222
```

---

## 5. Disable Password Login (Recommended)

Once SSH key access is confirmed, disable password-based SSH on the server:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:
```
PasswordAuthentication no
PermitRootLogin prohibit-password
```

Restart SSH:
```bash
service ssh restart
```

---

## Quick Reference

| Task | Command |
|---|---|
| Generate key | `ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""` |
| Authorize key | `cat id_ed25519.pub >> ~/.ssh/authorized_keys` |
| Extract from container | `docker cp <name>:/root/.ssh/id_ed25519 ./id_ed25519` |
| Fix local permissions | `chmod 600 ./id_ed25519` |
| SSH with key | `ssh -i ./id_ed25519 root@<host> -p <port>` |
| check if ssh is running | `service ssh status` |
---

## 6. Local Machine Configuration (Cloudflare Zero Trust)

To access the server via Cloudflare Tunnel from your **local machine** (Mac/Windows/Linux), follow these steps:

### A. Install cloudflared Locally
If you haven't already:
```bash
brew install cloudflared
```

### B. Authenticate with Cloudflare
Run this command to authenticate your local machine with your Cloudflare account:
```bash
cloudflared tunnel login
```
*(This will open a browser window for you to select your domain)*

### C. Update your SSH Config (Optional but Recommended)
To make logging in easier, add this to your `~/.ssh/config`:
```ssh
Host sumangali
    HostName sumangali.offlinesys.com
    User root
    IdentityFile ~/path/to/sumangali
    ProxyCommand /opt/homebrew/bin/cloudflared access ssh --hostname %h
```
*(Then you can just run `ssh sumangali`)*

---

## 7. Troubleshooting "no such host"

If you see `dial tcp: lookup sumangali.offlinesys.com: no such host`, it means one of the following:

1.  **Hostname Mismatch**: Your tunnel configuration in the Cloudflare Dashboard might be set to a different domain (e.g., `.shop` instead of `.com`). 
    *   **Check logs**: Run `docker exec offline-ubuntu systemctl status cloudflared` and look for the `ingress` config.
2.  **Missing DNS Record**: Ensure you have a **Public Hostname** entry in your Cloudflare Zero Trust Dashboard:
    *   **Hostname**: `sumangali.offlinesys.com`
    *   **Service Type**: `SSH`
    *   **URL**: `localhost:22`
3.  **Local Resolution**: As a temporary workaround, you can add the hostname to your local `/etc/hosts` file (though Cloudflare Access should handle this if configured correctly):
    ```bash
    sudo echo "127.0.0.1 sumangali.offlinesys.com" >> /etc/hosts
    ```

## Quick Reference Summary (Local Setup)

1. `brew install cloudflared`
2. `cloudflared tunnel login`
3. `docker cp offline-ubuntu:/root/.ssh/id_ed25519 ./sumangali`
4. `chmod 600 ./sumangali`
5. `ssh -i ./sumangali -o ProxyCommand="cloudflared access ssh --hostname sumangali.offlinesys.com" root@sumangali.offlinesys.com`

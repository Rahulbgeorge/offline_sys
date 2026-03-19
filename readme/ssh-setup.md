# SSH Key Setup

Guide for generating SSH keys and configuring SSH access, including extracting keys from Docker containers.

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

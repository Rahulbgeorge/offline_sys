# Ubuntu Server Setup Guide

Follow these steps to set up your Ubuntu server with secure SSH access using manually managed keys.

## 1. Local SSH Key Generation

Generate a secure SSH key locally. Use a meaningful name to identify it easily later.

```bash
# Generate the key with a custom name (e.g., store_key)
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/store_key
```

- When prompted, you skip the passphrase or provide a strong one.
- Save the private key (`~/.ssh/store_key`) to a safe backup location (like a password manager).

## 2. Add SSH Key to GitHub

1. Copy your public key content:
   ```bash
   cat ~/.ssh/store_key.pub
   ```
2. Go to your **GitHub Settings > SSH and GPG keys**.
3. Click **New SSH key**, give it a title (e.g., "Offline Sys - Sumangali"), and paste the content.

## 3. Ubuntu Server Setup & Key Import

When installing your Ubuntu server (or configuring it via your provider's dashboard):

1. Link your **GitHub Account** to the server during the SSH setup phase (most cloud providers allow importing keys directly from GitHub).
2. After the keys are imported, manually inspect the `~/.ssh/authorized_keys` file.
3. **Important:** Remove any unwanted or old keys that were automatically imported but are no longer needed.

## 4. Basic System Setup
`docker compose up`

- cloudflare preinstalled on the docker
```
# Add cloudflare gpg key
mkdir -p --mode=0755 /usr/share/keyrings

curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list

sudo apt-get update && sudo apt-get install cloudflared
```
    
# cross check if ssh is working on the system
`# verify ssh port is listening
ss -tulpn | grep 22
`

# Setup cloudfront on the system

- Go to cloudflare account
- Go to Zero Trust
- Go to Netword -> Overview -> Manage tunnels
- Add/Create a tunnel
   - enter <store_name>-ssh as name of tunnel
   - use the following commands to setup the tunnel link to the online system, available in cloudflare account 
        ```
        cloudflared service install <token_name>
        ```


# setup a strong password for the root user
```
# Generate a random password
password=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 20)
echo "Generated password: $password"

# Set it as the system password for the current user
echo "$USER:$password" | sudo chpasswd
echo "Password for '$USER' has been updated successfully."

```


# 5. How to Login to Remote Store Account
- `cloudflared` must be installed on your local system.
- Use the correct path to your private key (e.g., `~/.ssh/store_key`).

```bash
# Variables for the login command
host=sumangali5.offlinesys.shop
key_loc=~/.ssh/store_key 

# Run the SSH command using the Cloudflare Access Proxy
ssh -i $key_loc -o ProxyCommand="cloudflared access ssh --hostname $host" root@$host
```
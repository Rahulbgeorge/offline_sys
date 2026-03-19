## Basic Setup
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


# How to Login to Remote Store Account
- cloudflared should be installed on the system, to do this 
    ```
    host=sumangali.offlinesys.shop
    pem_loc=sumangali.pub
    ssh -i $pem_loc -o ProxyCommand="cloudflared access ssh --hostname $host" root@$host
    ```
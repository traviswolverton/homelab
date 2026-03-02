# Security Hardening

## Overview

- SSH **disabled** on 8 containers (no external access required)
- SSH **key-only authentication** on 3 maintenance containers
- Principle of least privilege throughout

## Containers with SSH Disabled

These containers have no SSH access — managed via Proxmox console only:

- radarr
- sonarr
- sonarr2
- seerr
- qbittorrent
- prowlarr
- tautulli
- bazarr

### How to disable SSH on a container

```bash
# From Proxmox host
pct exec <CTID> -- bash -c "
    systemctl stop ssh
    systemctl disable ssh
    systemctl mask ssh
"
```

## Containers with Key-Only SSH

These containers allow SSH but require key authentication (no passwords):

- pihole-1
- pihole-2  
- unifi (or your chosen maintenance containers)

### Setup key-only auth

```bash
# On the container
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh
```

### Add your public key

```bash
# From your admin machine
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@<container-ip>
```

## Verify SSH Status

Quick check across all containers from Proxmox host:

```bash
for CTID in $(pct list | awk 'NR>1 && $2=="running" {print $1}'); do
    NAME=$(pct config $CTID | grep '^hostname:' | awk '{print $2}')
    STATUS=$(pct exec $CTID -- systemctl is-active ssh 2>/dev/null || echo "not-found")
    echo "CT $CTID ($NAME): ssh=$STATUS"
done
```

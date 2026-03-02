# Proxmox Inventory

Last updated: 2026-03

## LXC Containers

| CT ID | Name | Purpose | SSH | Notes |
|-------|------|---------|-----|-------|
| — | radarr | Movie automation | Disabled | *arr stack |
| — | sonarr | TV automation (main) | Disabled | *arr stack |
| — | sonarr2 | TV automation (anime/alt) | Disabled | *arr stack |
| — | seerr | Request management (Seerr v3.0.1) | Disabled | Migrated from Overseerr |
| — | qbittorrent | Download client (fallback) | Disabled | Active when Premiumize fair use > 100pts |
| — | prowlarr | Indexer management | Disabled | *arr stack |
| — | tautulli | Plex monitoring & stats | Disabled | |
| — | bazarr | Subtitle automation | Disabled | *arr stack |
| — | unifi | UniFi Network controller | Disabled | |
| — | pihole-1 | Primary DNS / ad blocking | Key-only | Main Proxmox node |
| — | pihole-2 | Secondary DNS / ad blocking | Key-only | Raspberry Pi infrastructure node |

> SSH disabled on 8 containers. Key-only auth on maintenance containers.

## Virtual Machines

| VM ID | Name | Purpose | Notes |
|-------|------|---------|-------|
| — | haos | Home Assistant OS 10.3 | Home automation |
| — | ubuntu | General purpose Linux | Admin / tooling |
| — | dnd | D&D campaign tools | Personal |

## Raspberry Pi Infrastructure Node

Runs independently of main Proxmox node — survives main node outages.

| Service | Purpose |
|---------|---------|
| Pi-hole | Secondary DNS (pihole-2) |
| Proxmox Backup Server (PBS) | Automated backups of Proxmox VMs/CTs |
| NPM (planned) | Nginx Proxy Manager — reverse proxy |
| Gitea (planned) | Self-hosted git mirror |

## Storage

| Mount | Type | Size | Purpose |
|-------|------|------|---------|
| mergerfs pool | mergerfs | ~22TB | Unified media pool |
| — | WD 1TB | 1TB | — |
| — | WD 4TB × 2 | 8TB | — |
| — | WD 8TB × 2 | 16TB | — |

NFS shares exported from Proxmox host to containers.  
Thin-provisioned LXC disks — `fstrim` run weekly via maintenance scripts.

## Maintenance Schedule (Sunday)

| Time | Script | Action |
|------|--------|--------|
| 1:00 AM | proxmox-update | Update Proxmox host packages |
| 2:00 AM | lxc-update | Update all LXC container packages |
| 2:30 AM | arr-update | Update Radarr/Sonarr/Prowlarr/etc |
| 2:35 AM | seerr-update | Update Seerr |
| 2:40 AM | bazarr-update | Update Bazarr |
| 2:45 AM | pihole-update | Update Pi-hole |
| 3:00 AM | lxc-restart | Restart all LXC containers |

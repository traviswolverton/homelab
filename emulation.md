# Emulation

Details of emulation solutions, services, and media storage for a homelab

## Services

| Service | Architecture | Role | IP Address | Comments
|------|------|------|------|------|
| BATOCERA | VM Inside Proxmox Host | Linux Distro - front end and orchestration, backend file system | ???.???.??.??? | USB Passthrough from Proxmox Host to Batocera
| Gamelist Manager | Workstation/Local Install | Scraper Utility - scrapes data from various online metadata sources, updates/creates gamelist.xml | N/A | Directly reads/writes to/from SMB share
| IGIR | Workstation/Local Install - needs NodeJS | Consumes .DAT files produced from  online database(s) for ROM sets for comparison | N/A | Currently deployed on Windows Laptop
| RomVault | Workstation/Local Install | Compares .dat files for ROM sets against local storage, produces diff analysis - GUI analog to IGIR | N/A | Currently deployed on Windows Laptop

## .DAT Sources

Details of where to get .DAT lists for comparison in IGIR/RomVault

| System | Link
|------|------|
N64 | https://datomatic.no-intro.org/
SNES | https://datomatic.no-intro.org/
NES| https://datomatic.no-intro.org/
GBA| https://datomatic.no-intro.org/
GameCube | redump.org/


See [`docs/inventory.md`](docs/inventory.md) for full list.

**LXCs:** radarr · sonarr · sonarr2 · overseerr (→ seerr) · qbittorrent · prowlarr · tautulli · bazarr · unifi · pihole × 2  
**VMs:** haos · ubuntu · dnd

## Network

See [`docs/network-topology.md`](docs/network-topology.md) for full topology.  
See [`rack/rack-layout.html`](rack/rack-layout.html) for rack diagram.

**Core gear:** UCG-Fiber · UniFi Pro Max 16 PoE · U7 Pro APs × 2  
**Storage network:** Proxmox on 10G SFP+ direct to switch (LAN traffic off router)

## Scripts

| Script | Schedule | Purpose |
|--------|----------|---------|
| [`scripts/maintenance/proxmox-update.sh`](scripts/maintenance/proxmox-update.sh) | Sun 1:00 AM | Update Proxmox host |
| [`scripts/maintenance/lxc-update.sh`](scripts/maintenance/lxc-update.sh) | Sun 2:00 AM | Update all LXC containers |
| [`scripts/maintenance/arr-update.sh`](scripts/maintenance/arr-update.sh) | Sun 2:30 AM | Update *arr apps |
| [`scripts/maintenance/seerr-update.sh`](scripts/maintenance/seerr-update.sh) | Sun 2:35 AM | Update Seerr |
| [`scripts/maintenance/bazarr-update.sh`](scripts/maintenance/bazarr-update.sh) | Sun 2:40 AM | Update Bazarr |
| [`scripts/maintenance/pihole-update.sh`](scripts/maintenance/pihole-update.sh) | Sun 2:45 AM | Update Pi-hole |
| [`scripts/maintenance/lxc-restart.sh`](scripts/maintenance/lxc-restart.sh) | Sun 3:00 AM | Restart all LXCs |
| [`scripts/monitoring/premiumize-fairuse.sh`](scripts/monitoring/premiumize-fairuse.sh) | cron (frequent) | Switch download client based on Premiumize fair use score |

## Storage

mergerfs pool combining all data drives into a unified `/mnt/media` mount.  
NFS shares exported to LXC containers.  
Thin-provisioned LXC disks — regular `fstrim` via maintenance scripts.

## Security

- SSH disabled on 8 containers (no external access needed)
- Key-only authentication on 3 maintenance containers
- Principle of least privilege throughout

## Future

- [ ] Gitea on RPi (self-hosted git mirror)
- [ ] NPM (Nginx Proxy Manager) on RPi
- [ ] NUT UPS monitoring (once USB connected)
- [ ] UCG-Fiber + Pro Max 16 PoE network migration
- [ ] DNS management → Pi-hole (away from USG built-in)

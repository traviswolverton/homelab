#!/bin/bash
# proxmox-update.sh — Update Proxmox host packages
# Schedule: Sunday 1:00 AM

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/proxmox-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Proxmox host update started ==="

apt-get update -qq 2>&1 | tee -a "$LOGFILE"
UPGRADE_OUTPUT=$(apt-get upgrade -y 2>&1)
echo "$UPGRADE_OUTPUT" | tee -a "$LOGFILE"

if echo "$UPGRADE_OUTPUT" | grep -q "upgraded,"; then
    UPGRADED=$(echo "$UPGRADE_OUTPUT" | grep "upgraded," | tail -1)
    log "Packages updated: $UPGRADED"
else
    log "No packages to update"
fi

apt-get autoremove -y -qq 2>&1 | tee -a "$LOGFILE"
apt-get autoclean -qq 2>&1 | tee -a "$LOGFILE"

log "=== Proxmox host update complete ==="
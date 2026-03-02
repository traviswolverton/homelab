#!/bin/bash
# proxmox-update.sh
# Updates Proxmox host packages
# Schedule: Sunday 1:00 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/proxmox-update.log"
EMAIL="your@gmail.com"  # update this

mkdir -p "$(dirname "$LOGFILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

send_email() {
    local subject="$1"
    local body="$2"
    echo "$body" | msmtp -a gmail "$EMAIL" \
        --subject="$subject" 2>/dev/null || true
}

log "=== Proxmox host update started ==="

# Update package lists and upgrade
apt-get update -qq 2>&1 | tee -a "$LOGFILE"
UPGRADE_OUTPUT=$(apt-get upgrade -y 2>&1)
echo "$UPGRADE_OUTPUT" | tee -a "$LOGFILE"

# Check if anything was upgraded
if echo "$UPGRADE_OUTPUT" | grep -q "upgraded,"; then
    UPGRADED=$(echo "$UPGRADE_OUTPUT" | grep "upgraded," | tail -1)
    log "Packages updated: $UPGRADED"
    send_email "[homelab] Proxmox host updated" \
        "Proxmox host update completed.\n\n$UPGRADED\n\nFull log: $LOGFILE"
else
    log "No packages to update"
fi

# Clean up
apt-get autoremove -y -qq 2>&1 | tee -a "$LOGFILE"
apt-get autoclean -qq 2>&1 | tee -a "$LOGFILE"

log "=== Proxmox host update complete ==="

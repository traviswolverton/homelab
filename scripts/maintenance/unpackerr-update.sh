#!/bin/bash
# unpackerr-update.sh — Update Unpackerr in CT 108
# Schedule: Sunday 2:43 AM

export PATH=$PATH:/usr/sbin
source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/unpackerr-update.log"
mkdir -p "$(dirname "$LOGFILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"; }

log "=== Unpackerr update started ==="

/usr/sbin/pct exec $CT_QBITTORRENT -- bash -c "apt update -qq && apt install --only-upgrade unpackerr -y && systemctl restart unpackerr" 2>&1 | tee -a "$LOGFILE"

if [ $? -eq 0 ]; then
    log "Unpackerr updated successfully"
else
    log "Unpackerr update FAILED"
fi

log "=== Unpackerr update complete ==="
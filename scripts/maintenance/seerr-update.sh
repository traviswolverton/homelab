#!/bin/bash
# seerr-update.sh — Update Seerr
# Schedule: Sunday 2:35 AM

export PATH=$PATH:/usr/sbin

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/seerr-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Seerr update started ==="

OUTPUT=$(/usr/sbin/pct exec "$CT_SEERR" -- bash -c "
    cd /opt/seerr
    sudo -u seerr git pull 2>&1
    sudo -u seerr pnpm install 2>&1
    sudo -u seerr pnpm build 2>&1
    systemctl restart seerr 2>&1
" 2>&1)

if [ $? -eq 0 ]; then
    log "Seerr updated successfully"
else
    log "Seerr update FAILED: $OUTPUT"
fi

log "=== Seerr update complete ==="
#!/bin/bash
# homarr-update.sh — Update Homarr application
# Schedule: Sunday 2:50 AM

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/homarr-update.log"
mkdir -p "$(dirname "$LOGFILE")"
CTID=101

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Homarr update started ==="

OUTPUT=$(/usr/sbin/pct exec "$CTID" -- bash -c "PHS_SILENT=1 update" 2>&1)
EXIT=$?

if [ $EXIT -eq 0 ]; then
    log "Update OK"
    log "$OUTPUT"
else
    log "Update FAILED — exit code $EXIT"
    log "$OUTPUT"
fi

log "=== Homarr update complete ==="
#!/bin/bash
# bazarr-update.sh — Update Bazarr
# Schedule: Sunday 2:40 AM

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/bazarr-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Bazarr update started ==="

RESPONSE=$(curl -s -X POST \
    "http://$IP_BAZARR:$PORT_BAZARR/api/system/tasks" \
    -H "X-API-KEY: $API_BAZARR" \
    -H "Content-Type: application/json" \
    -d '{"taskid":"update_bazarr"}' \
    --max-time 30 2>&1)

if [ $? -eq 0 ]; then
    log "Bazarr update triggered"
else
    log "Bazarr update FAILED: $RESPONSE"
fi

log "=== Bazarr update complete ==="
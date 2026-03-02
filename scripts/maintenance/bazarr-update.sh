#!/bin/bash
# bazarr-update.sh
# Updates Bazarr subtitle automation
# Schedule: Sunday 2:40 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/bazarr-update.log"
EMAIL="your@gmail.com"  # update this
BAZARR_CT_ID=105        # update to your CT ID
BAZARR_PORT=6767
BAZARR_API_KEY="YOUR_BAZARR_API_KEY"

mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Bazarr update started ==="

# Trigger update via API
RESPONSE=$(curl -s -X POST \
    "http://localhost:$BAZARR_PORT/api/system/tasks" \
    -H "X-API-KEY: $BAZARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"taskid":"update_bazarr"}' \
    --max-time 30 2>&1)

if [ $? -eq 0 ]; then
    log "Bazarr update triggered"
    echo "Bazarr update triggered." | msmtp -a gmail "$EMAIL" \
        --subject="[homelab] Bazarr updated" 2>/dev/null || true
else
    log "Bazarr update FAILED: $RESPONSE"
    echo "Bazarr update failed.\n\n$RESPONSE" | msmtp -a gmail "$EMAIL" \
        --subject="[homelab] Bazarr update FAILED" 2>/dev/null || true
fi

log "=== Bazarr update complete ==="

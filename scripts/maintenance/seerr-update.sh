#!/bin/bash
# seerr-update.sh
# Updates Seerr (Jellyseerr/Overseerr fork)
# Schedule: Sunday 2:35 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/seerr-update.log"
EMAIL="your@gmail.com"  # update this
SEERR_CT_ID=104         # update to your CT ID

mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Seerr update started ==="

# Pull latest image and restart container
OUTPUT=$(pct exec "$SEERR_CT_ID" -- bash -c "
    cd /opt/seerr 2>/dev/null || cd /opt/overseerr 2>/dev/null
    docker compose pull 2>&1
    docker compose up -d 2>&1
" 2>&1)

if [ $? -eq 0 ]; then
    log "Seerr updated successfully"
    echo "Seerr update complete." | msmtp -a gmail "$EMAIL" \
        --subject="[homelab] Seerr updated" 2>/dev/null || true
else
    log "Seerr update FAILED: $OUTPUT"
    echo "Seerr update failed.\n\n$OUTPUT" | msmtp -a gmail "$EMAIL" \
        --subject="[homelab] Seerr update FAILED" 2>/dev/null || true
fi

log "=== Seerr update complete ==="

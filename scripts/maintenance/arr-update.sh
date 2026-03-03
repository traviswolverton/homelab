#!/bin/bash
# arr-update.sh — Update *arr applications
# Schedule: Sunday 2:30 AM

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/arr-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

ARR_APPS=(
    "radarr|$PORT_RADARR|$API_RADARR|$IP_RADARR|v3"
    "sonarr|$PORT_SONARR|$API_SONARR|$IP_SONARR|v3"
    "sonarr2|$PORT_SONARR2|$API_SONARR2|$IP_SONARR2|v3"
    "prowlarr|$PORT_PROWLARR|$API_PROWLARR|$IP_PROWLARR|v1"
)

log "=== *arr update started ==="

SUMMARY=""
FAILED=""

for APP_ENTRY in "${ARR_APPS[@]}"; do
    IFS='|' read -r APP_NAME PORT API_KEY IP API_VER <<< "$APP_ENTRY"
    log "Updating $APP_NAME..."

     RESPONSE=$(curl -s -X POST \
    "http://$IP:$PORT/api/$API_VER/command" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name":"ApplicationUpdate"}' \
    --max-time 30 2>&1)

    if echo "$RESPONSE" | grep -q '"id"'; then
        log "  $APP_NAME: update triggered"
        SUMMARY="$SUMMARY\n  $APP_NAME: triggered"
        sleep 30
    else
        log "  $APP_NAME: FAILED — $RESPONSE"
        FAILED="$FAILED\n  $APP_NAME"
    fi
done

log "=== *arr update complete ==="

if [ -n "$FAILED" ]; then
    log "=== *arr update completed with failures ==="
else
    log "=== *arr update complete ==="
fi

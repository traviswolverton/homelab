#!/bin/bash
# arr-update.sh
# Updates *arr applications (Radarr, Sonarr, Sonarr2, Prowlarr)
# Schedule: Sunday 2:30 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/arr-update.log"
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

# Array of arr apps: "name|ct_id|port|api_key"
# Update CT IDs and API keys to match your environment
ARR_APPS=(
    "radarr|100|7878|YOUR_RADARR_API_KEY"
    "sonarr|101|8989|YOUR_SONARR_API_KEY"
    "sonarr2|102|8990|YOUR_SONARR2_API_KEY"
    "prowlarr|103|9696|YOUR_PROWLARR_API_KEY"
)

log "=== *arr update started ==="

SUMMARY=""
FAILED=""

for APP_ENTRY in "${ARR_APPS[@]}"; do
    IFS='|' read -r APP_NAME CT_ID PORT API_KEY <<< "$APP_ENTRY"
    log "Updating $APP_NAME (CT $CT_ID)..."

    # Trigger update check via API
    RESPONSE=$(curl -s -X POST \
        "http://localhost:$PORT/api/v3/command" \
        -H "X-Api-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"name":"ApplicationUpdate"}' \
        --max-time 30 2>&1)

    if echo "$RESPONSE" | grep -q '"id"'; then
        log "  $APP_NAME: update triggered"
        SUMMARY="$SUMMARY\n  $APP_NAME: update triggered"
        sleep 30  # give it time to download and restart
    else
        log "  $APP_NAME: FAILED — $RESPONSE"
        FAILED="$FAILED\n  $APP_NAME"
    fi
done

log "=== *arr update complete ==="

if [ -n "$FAILED" ]; then
    send_email "[homelab] *arr update — FAILURES" \
        "*arr update completed with failures.\n\nFailed:$FAILED\n\nTriggered:$SUMMARY\n\nLog: $LOGFILE"
else
    send_email "[homelab] *arr update complete" \
        "All *arr apps updated successfully.\n$SUMMARY\n\nLog: $LOGFILE"
fi

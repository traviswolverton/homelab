#!/bin/bash
# premiumize-fairuse.sh — Monitor fair use score, switch download client
# Dual threshold: below 100 -> qBittorrent, above 500 -> RDTClient
# Cron: */15 * * * * /opt/homelab/scripts/monitoring/premiumize-fairuse.sh

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/premiumize-fairuse.log"
STATE_FILE="/var/lib/maintenance/download-client-state"
THRESHOLD_LOW=100
THRESHOLD_HIGH=500

mkdir -p "$(dirname "$LOGFILE")" "$(dirname "$STATE_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

CURRENT_CLIENT=$(cat "$STATE_FILE" 2>/dev/null || echo "rdtclient")

FAIRUSE_RESPONSE=$(curl -s \
    "https://www.premiumize.me/api/account/info?apikey=$API_PREMIUMIZE" \
    --max-time 15 2>&1)

if ! echo "$FAIRUSE_RESPONSE" | grep -q '"status":"success"'; then
    log "ERROR: Failed to fetch Premiumize score — $FAIRUSE_RESPONSE"
    exit 1
fi

SCORE=$(echo "$FAIRUSE_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
limit_used = float(data.get('limit_used', 0) or 0)
print(int(limit_used * 1000))
" 2>/dev/null)

if [ -z "$SCORE" ]; then
    log "ERROR: Could not parse fair use score"
    exit 1
fi

log "Fair use score: $SCORE | Current client: $CURRENT_CLIENT"

NEW_CLIENT="$CURRENT_CLIENT"

if [ "$CURRENT_CLIENT" = "rdtclient" ] && [ "$SCORE" -gt "$THRESHOLD_LOW" ]; then
    NEW_CLIENT="qbittorrent"
    log "Score $SCORE < $THRESHOLD_LOW — switching to qBittorrent"
elif [ "$CURRENT_CLIENT" = "qbittorrent" ] && [ "$SCORE" -lt "$THRESHOLD_HIGH" ]; then
    NEW_CLIENT="rdtclient"
    log "Score $SCORE > $THRESHOLD_HIGH — switching back to RDTClient"
fi

if [ "$NEW_CLIENT" != "$CURRENT_CLIENT" ]; then
    TARGET_NAME="RDTClient"
    [ "$NEW_CLIENT" = "qbittorrent" ] && TARGET_NAME="qBittorrent"

    for APP in "radarr|$PORT_RADARR|$API_RADARR|$IP_RADARR" "sonarr|$PORT_SONARR|$API_SONARR|$IP_SONARR" "sonarr2|$PORT_SONARR2|$API_SONARR2|$IP_SONARR2"; do
        IFS='|' read -r ANAME PORT AKEY AIP <<< "$APP"
        CLIENTS=$(curl -s "http://$AIP:$PORT/api/v3/downloadclient" -H "X-Api-Key: $AKEY")
        echo "$CLIENTS" | python3 -c "
import sys, json
from urllib import request
clients = json.load(sys.stdin)
for c in clients:
    c['enable'] = '$TARGET_NAME'.lower() in c['name'].lower()
    req = request.Request(
        'http://$AIP:$PORT/api/v3/downloadclient/' + str(c['id']),
        data=json.dumps(c).encode(),
        headers={'X-Api-Key': '$AKEY', 'Content-Type': 'application/json'},
        method='PUT'
    )
    request.urlopen(req)
" 2>/dev/null
        log "  $ANAME: switched to $TARGET_NAME"
    done

    echo "$NEW_CLIENT" > "$STATE_FILE"

    echo -e "Subject: [homelab] Download client -> $TARGET_NAME\n\nPremiumize score: $SCORE\n\nSwitched: $CURRENT_CLIENT -> $NEW_CLIENT\n\nThresholds: LOW=$THRESHOLD_LOW HIGH=$THRESHOLD_HIGH" | msmtp "$EMAIL"

    log "Switch complete: $CURRENT_CLIENT -> $NEW_CLIENT"
fi
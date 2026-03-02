#!/bin/bash
# premiumize-fairuse.sh
# Monitors Premiumize fair use score and switches download client accordingly
#
# Dual-threshold logic (prevents flip-flopping):
#   Score drops below 100  → switch TO qBittorrent
#   Score rises above 500  → switch BACK to RDTClient (Premiumize)
#
# Run via cron — recommended every 15-30 minutes
# Example crontab: */15 * * * * /opt/scripts/monitoring/premiumize-fairuse.sh

LOGFILE="/var/log/maintenance/premiumize-fairuse.log"
EMAIL="your@gmail.com"           # update this
PREMIUMIZE_API_KEY="YOUR_KEY"    # update this

# qBittorrent settings
QB_HOST="http://localhost:8080"  # update if different
QB_USER="admin"
QB_PASS="your_qb_password"       # update this

# Radarr/Sonarr API settings — update CT IDs/ports/keys
RADARR_URL="http://localhost:7878"
RADARR_API_KEY="YOUR_RADARR_API_KEY"
SONARR_URL="http://localhost:8989"
SONARR_API_KEY="YOUR_SONARR_API_KEY"
SONARR2_URL="http://localhost:8990"
SONARR2_API_KEY="YOUR_SONARR2_API_KEY"

# State file to track current active client
STATE_FILE="/var/lib/maintenance/download-client-state"
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOGFILE")"

# Thresholds
THRESHOLD_LOW=100    # switch TO qBittorrent below this
THRESHOLD_HIGH=500   # switch BACK to RDTClient above this

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

send_email() {
    echo "$2" | msmtp -a gmail "$EMAIL" --subject="$1" 2>/dev/null || true
}

# Get current state (default: rdtclient)
CURRENT_CLIENT=$(cat "$STATE_FILE" 2>/dev/null || echo "rdtclient")

# Fetch Premiumize fair use score
FAIRUSE_RESPONSE=$(curl -s \
    "https://www.premiumize.me/api/account/info?apikey=$PREMIUMIZE_API_KEY" \
    --max-time 15 2>&1)

if ! echo "$FAIRUSE_RESPONSE" | grep -q '"status":"success"'; then
    log "ERROR: Failed to fetch Premiumize fair use score — $FAIRUSE_RESPONSE"
    exit 1
fi

SCORE=$(echo "$FAIRUSE_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(int(data.get('premium_until', 0) or 0))
" 2>/dev/null)

# Fallback jq parse if python3 not available
if [ -z "$SCORE" ]; then
    SCORE=$(echo "$FAIRUSE_RESPONSE" | grep -o '"fair_use_points":[0-9]*' | grep -o '[0-9]*')
fi

if [ -z "$SCORE" ]; then
    log "ERROR: Could not parse fair use score from response"
    exit 1
fi

log "Fair use score: $SCORE | Current client: $CURRENT_CLIENT"

# Determine if switch is needed
NEW_CLIENT="$CURRENT_CLIENT"

if [ "$CURRENT_CLIENT" = "rdtclient" ] && [ "$SCORE" -lt "$THRESHOLD_LOW" ]; then
    NEW_CLIENT="qbittorrent"
    log "Score $SCORE < $THRESHOLD_LOW — switching to qBittorrent"
elif [ "$CURRENT_CLIENT" = "qbittorrent" ] && [ "$SCORE" -gt "$THRESHOLD_HIGH" ]; then
    NEW_CLIENT="rdtclient"
    log "Score $SCORE > $THRESHOLD_HIGH — switching back to RDTClient"
fi

# Apply switch if needed
if [ "$NEW_CLIENT" != "$CURRENT_CLIENT" ]; then

    switch_arr_client() {
        local APP_URL="$1"
        local API_KEY="$2"
        local APP_NAME="$3"
        local CLIENT_NAME="$4"  # must match download client name in *arr

        # Get download client list
        CLIENTS=$(curl -s "$APP_URL/api/v3/downloadclient" \
            -H "X-Api-Key: $API_KEY" 2>&1)

        # Enable target, disable other
        echo "$CLIENTS" | python3 -c "
import sys, json
clients = json.load(sys.stdin)
for c in clients:
    if '$CLIENT_NAME'.lower() in c['name'].lower():
        c['enable'] = True
    else:
        c['enable'] = False
    print(json.dumps(c))
" 2>/dev/null | while read -r CLIENT_JSON; do
            CLIENT_ID=$(echo "$CLIENT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
            curl -s -X PUT "$APP_URL/api/v3/downloadclient/$CLIENT_ID" \
                -H "X-Api-Key: $API_KEY" \
                -H "Content-Type: application/json" \
                -d "$CLIENT_JSON" > /dev/null 2>&1
        done

        log "  $APP_NAME: switched to $CLIENT_NAME"
    }

    TARGET_CLIENT_NAME=""
    if [ "$NEW_CLIENT" = "qbittorrent" ]; then
        TARGET_CLIENT_NAME="qBittorrent"
    else
        TARGET_CLIENT_NAME="RDTClient"
    fi

    switch_arr_client "$RADARR_URL" "$RADARR_API_KEY" "Radarr" "$TARGET_CLIENT_NAME"
    switch_arr_client "$SONARR_URL" "$SONARR_API_KEY" "Sonarr" "$TARGET_CLIENT_NAME"
    switch_arr_client "$SONARR2_URL" "$SONARR2_API_KEY" "Sonarr2" "$TARGET_CLIENT_NAME"

    # Save new state
    echo "$NEW_CLIENT" > "$STATE_FILE"

    send_email "[homelab] Download client switched to $TARGET_CLIENT_NAME" \
        "Premiumize fair use score: $SCORE\n\nSwitched from $CURRENT_CLIENT to $NEW_CLIENT.\n\nThresholds: LOW=$THRESHOLD_LOW, HIGH=$THRESHOLD_HIGH"

    log "Switch complete: $CURRENT_CLIENT → $NEW_CLIENT"
fi

#!/bin/bash
# lxc-update.sh
# Updates all running LXC containers
# Schedule: Sunday 2:00 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/lxc-update.log"
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

log "=== LXC container update started ==="

# Get all running containers
CONTAINERS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

if [ -z "$CONTAINERS" ]; then
    log "No running containers found"
    exit 0
fi

SUMMARY=""
FAILED=""

for CTID in $CONTAINERS; do
    NAME=$(pct config "$CTID" | grep '^hostname:' | awk '{print $2}')
    log "Updating CT $CTID ($NAME)..."

    OUTPUT=$(pct exec "$CTID" -- bash -c "
        apt-get update -qq 2>&1
        apt-get upgrade -y 2>&1
        apt-get autoremove -y -qq 2>&1
        apt-get autoclean -qq 2>&1
    " 2>&1)

    if [ $? -eq 0 ]; then
        UPGRADED=$(echo "$OUTPUT" | grep "upgraded," | tail -1)
        log "  CT $CTID ($NAME): OK — $UPGRADED"
        SUMMARY="$SUMMARY\n  CT $CTID ($NAME): $UPGRADED"
    else
        log "  CT $CTID ($NAME): FAILED"
        FAILED="$FAILED\n  CT $CTID ($NAME)"
    fi

    # Run fstrim to reclaim freed blocks on thin-provisioned storage
    pct exec "$CTID" -- fstrim -av 2>/dev/null | tee -a "$LOGFILE"
done

log "=== LXC container update complete ==="

if [ -n "$FAILED" ]; then
    send_email "[homelab] LXC update — FAILURES" \
        "LXC update completed with failures.\n\nFailed:$FAILED\n\nUpdated:$SUMMARY\n\nLog: $LOGFILE"
else
    send_email "[homelab] LXC update complete" \
        "All LXC containers updated successfully.\n$SUMMARY\n\nLog: $LOGFILE"
fi

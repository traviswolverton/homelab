#!/bin/bash
# lxc-restart.sh
# Gracefully restarts all LXC containers after weekly updates
# Schedule: Sunday 3:00 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/lxc-restart.log"
EMAIL="your@gmail.com"  # update this

# Containers to skip (comma-separated CT IDs) — e.g. critical infra you don't want bounced
SKIP_CTS=""

mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== LXC restart started ==="

CONTAINERS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')
SUMMARY=""

for CTID in $CONTAINERS; do
    # Skip if in exclusion list
    if echo "$SKIP_CTS" | grep -qw "$CTID"; then
        log "  CT $CTID: skipped (exclusion list)"
        continue
    fi

    NAME=$(pct config "$CTID" | grep '^hostname:' | awk '{print $2}')
    log "  Restarting CT $CTID ($NAME)..."

    pct restart "$CTID" 2>&1 | tee -a "$LOGFILE"

    if [ $? -eq 0 ]; then
        SUMMARY="$SUMMARY\n  CT $CTID ($NAME): restarted"
        sleep 5  # stagger restarts
    else
        SUMMARY="$SUMMARY\n  CT $CTID ($NAME): FAILED"
        log "  CT $CTID ($NAME): restart FAILED"
    fi
done

log "=== LXC restart complete ==="

echo -e "Weekly LXC restart complete.\n$SUMMARY\n\nLog: $LOGFILE" | \
    msmtp -a gmail "$EMAIL" --subject="[homelab] Weekly maintenance complete" 2>/dev/null || true

#!/bin/bash
# lxc-update.sh — Update all running LXC containers
# Schedule: Sunday 2:00 AM

export PATH=$PATH:/usr/sbin

source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/lxc-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== LXC container update started ==="

CONTAINERS=$(/usr/sbin/pct list | awk 'NR>1 && $2=="running" {print $1}' | sort -n)
SUMMARY=""
FAILED=""

for CTID in $CONTAINERS; do
    NAME=$(/usr/sbin/pct config "$CTID" | grep '^hostname:' | awk '{print $2}')
    log "Updating CT $CTID ($NAME)..."

    OUTPUT=$(/usr/sbin/pct exec "$CTID" -- bash -c "
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

    /usr/sbin/pct exec "$CTID" -- fstrim -av 2>/dev/null | tee -a "$LOGFILE"
done

log "=== LXC container update complete ==="

if [ -n "$FAILED" ]; then
    log "Completed with failures:$FAILED"
else
    log "All containers updated successfully"
fi
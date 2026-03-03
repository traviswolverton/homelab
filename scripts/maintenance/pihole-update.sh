#!/bin/bash
# pihole-update.sh — Update all Pi-hole instances
# Schedule: Sunday 2:45 AM

export PATH=$PATH:/usr/sbin
source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/pihole-update.log"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Pi-hole update started ==="

log "Updating pihole-main (CT $CT_PIHOLE1)..."
/usr/sbin/pct exec "$CT_PIHOLE1" -- /usr/local/bin/pihole -up 2>&1 | tee -a "$LOGFILE"
[ ${PIPESTATUS[0]} -eq 0 ] && log "  pihole-main: OK" || log "  pihole-main: FAILED"

log "Updating pihole-kids (CT $CT_PIHOLE2)..."
/usr/sbin/pct exec "$CT_PIHOLE2" -- /usr/local/bin/pihole -up 2>&1 | tee -a "$LOGFILE"
[ ${PIPESTATUS[0]} -eq 0 ] && log "  pihole-kids: OK" || log "  pihole-kids: FAILED"

log "Updating pihole-rpi ($PIHOLE3_HOST)..."
if ping -c 1 -W 3 "$PIHOLE3_HOST" > /dev/null 2>&1; then
    ssh -o ConnectTimeout=10 "$PIHOLE3_USER@$PIHOLE3_HOST" "/usr/local/bin/pihole -up 2>&1" | tee -a "$LOGFILE"
    [ ${PIPESTATUS[0]} -eq 0 ] && log "  pihole-rpi: OK" || log "  pihole-rpi: FAILED"
else
    log "  pihole-rpi: SKIPPED (unreachable)"
fi

log "=== Pi-hole update complete ==="
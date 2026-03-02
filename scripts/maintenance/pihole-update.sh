#!/bin/bash
# pihole-update.sh
# Updates Pi-hole gravity and core on both instances
# Schedule: Sunday 2:45 AM
# Part of weekly maintenance suite

LOGFILE="/var/log/maintenance/pihole-update.log"
EMAIL="your@gmail.com"  # update this

# CT IDs for both Pi-hole instances
PIHOLE_MAIN_CT=106     # pihole-1 on Proxmox node — update to your CT ID
PIHOLE_PI_HOST="192.168.1.x"  # RPi Pi-hole — update to your RPi IP

mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

log "=== Pi-hole update started ==="

SUMMARY=""

# Update pihole-1 (Proxmox CT)
log "Updating pihole-1 (CT $PIHOLE_MAIN_CT)..."
OUTPUT=$(pct exec "$PIHOLE_MAIN_CT" -- bash -c "
    pihole -up 2>&1
    pihole -g 2>&1
" 2>&1)

if [ $? -eq 0 ]; then
    log "  pihole-1: OK"
    SUMMARY="$SUMMARY\n  pihole-1: updated"
else
    log "  pihole-1: FAILED — $OUTPUT"
    SUMMARY="$SUMMARY\n  pihole-1: FAILED"
fi

# Update pihole-2 (RPi — via SSH)
log "Updating pihole-2 (RPi $PIHOLE_PI_HOST)..."
OUTPUT=$(ssh -o ConnectTimeout=10 pi@"$PIHOLE_PI_HOST" "
    pihole -up 2>&1
    pihole -g 2>&1
" 2>&1)

if [ $? -eq 0 ]; then
    log "  pihole-2: OK"
    SUMMARY="$SUMMARY\n  pihole-2: updated"
else
    log "  pihole-2: FAILED — $OUTPUT"
    SUMMARY="$SUMMARY\n  pihole-2: FAILED"
fi

log "=== Pi-hole update complete ==="

echo -e "Pi-hole update results:\n$SUMMARY\n\nLog: $LOGFILE" | \
    msmtp -a gmail "$EMAIL" --subject="[homelab] Pi-hole updated" 2>/dev/null || true

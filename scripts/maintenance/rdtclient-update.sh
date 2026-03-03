#!/bin/bash
# rdtclient-update.sh — Update rdt-client (CT 112)
# Schedule: Sunday 2:42 AM

export PATH=$PATH:/usr/sbin
source /opt/homelab/configs/.env

LOGFILE="/var/log/maintenance/rdtclient-update.log"
VERSION_FILE="/opt/rdtclient/version.txt"
INSTALL_DIR="/opt/rdtclient"
GITHUB_API="https://api.github.com/repos/rogerfar/rdt-client/releases/latest"

mkdir -p "$(dirname "$LOGFILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"; }

log "=== rdt-client update check started ==="

INSTALLED_VERSION=$(/usr/sbin/pct exec $CT_RDTCLIENT -- bash -c "cat $VERSION_FILE 2>/dev/null")
[ -z "$INSTALLED_VERSION" ] && INSTALLED_VERSION="unknown"
log "  Installed version: $INSTALLED_VERSION"

GITHUB_RESPONSE=$(curl -s --max-time 15 "$GITHUB_API")

LATEST_VERSION=$(echo "$GITHUB_RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tag_name', ''))
" 2>/dev/null)

DOWNLOAD_URL=$(echo "$GITHUB_RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assets = d.get('assets', [])
for a in assets:
    if a.get('name','').endswith('.zip'):
        print(a.get('browser_download_url',''))
        break
" 2>/dev/null)

if [ -z "$LATEST_VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
    log "  ERROR: Could not retrieve latest version from GitHub"
    exit 1
fi

log "  Latest version: $LATEST_VERSION"

if [ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]; then
    log "  rdt-client is up to date"
    exit 0
fi

log "  Update available: $INSTALLED_VERSION -> $LATEST_VERSION"

mkdir -p /tmp/rdtclient-update
curl -sL --max-time 120 "$DOWNLOAD_URL" -o /tmp/rdtclient-update/RealDebridClient.zip

if [ ! -f /tmp/rdtclient-update/RealDebridClient.zip ]; then
    log "  ERROR: Download failed"
    rm -rf /tmp/rdtclient-update
    exit 1
fi
/usr/sbin/pct push $CT_RDTCLIENT /tmp/rdtclient-update/RealDebridClient.zip /tmp/RealDebridClient.zip
/usr/sbin/pct exec $CT_RDTCLIENT -- systemctl stop rdtclient
sleep 3

/usr/sbin/pct exec $CT_RDTCLIENT -- bash -c "
    mkdir -p /tmp/rdtclient-update
    unzip -o /tmp/RealDebridClient.zip -d /tmp/rdtclient-update/ > /dev/null 2>&1
    cp $INSTALL_DIR/appsettings.json /tmp/appsettings.json.bak
    cp -r /tmp/rdtclient-update/* $INSTALL_DIR/
    cp /tmp/appsettings.json.bak $INSTALL_DIR/appsettings.json
    echo '$LATEST_VERSION' > $VERSION_FILE
    rm -rf /tmp/rdtclient-update /tmp/RealDebridClient.zip /tmp/appsettings.json.bak
"

rm -rf /tmp/rdtclient-update
/usr/sbin/pct exec $CT_RDTCLIENT -- systemctl start rdtclient
sleep 5

STATUS=$(/usr/sbin/pct exec $CT_RDTCLIENT -- systemctl is-active rdtclient)

if [ "$STATUS" == "active" ]; then
    log "  rdt-client updated to $LATEST_VERSION"
else
    log "  ERROR: Service failed to start after update to $LATEST_VERSION"
fi

log "=== rdt-client update check complete ==="
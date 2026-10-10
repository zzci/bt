#!/bin/sh
set -e

: "${WEBUI_PORT:=8080}"
: "${BT_PORT:=6881}"

CONF=/data/qBittorrent/config/qBittorrent.conf

mkdir -p /data /downloads

# PUID/PGID env > owner of /data (when non-root) > 1000
if [ -z "$PUID" ] || [ -z "$PGID" ]; then
    probe_uid="$(stat -c '%u' /data)"
    if [ "$probe_uid" != "0" ]; then
        : "${PUID:=$probe_uid}"
        : "${PGID:=$(stat -c '%g' /data)}"
    fi
fi
: "${PUID:=1000}"
: "${PGID:=1000}"

# Seed defaults on first start only; later changes belong to the WebUI.
if [ ! -f "$CONF" ]; then
    mkdir -p "$(dirname "$CONF")"
    cat > "$CONF" <<EOF
[BitTorrent]
Session\DefaultSavePath=/downloads
Session\TempPath=/downloads/incomplete

[Preferences]
WebUI\Address=*
EOF
fi

chown -R "$PUID:$PGID" /data
chown "$PUID:$PGID" /downloads

export HOME=/data
exec su-exec "$PUID:$PGID" qbittorrent-nox \
    --profile=/data \
    --webui-port="$WEBUI_PORT" \
    --torrenting-port="$BT_PORT" \
    --confirm-legal-notice \
    "$@"

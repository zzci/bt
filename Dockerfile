FROM alpine:3.24

# Static qbittorrent-nox build (WebUI included) from
# https://github.com/userdocs/qbittorrent-nox-static/releases
ARG QBT_VERSION=5.2.4
ARG LIBTORRENT_VERSION=2.0.15
ARG TARGETARCH

RUN apk add --no-cache ca-certificates tzdata su-exec openssl && \
    QBT_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    wget -qO /usr/local/bin/qbittorrent-nox \
      "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBT_VERSION}_v${LIBTORRENT_VERSION}/${QBT_ARCH}-qbittorrent-nox" && \
    chmod +x /usr/local/bin/qbittorrent-nox && \
    qbittorrent-nox --version

COPY docker-entrypoint.sh reset-password /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/reset-password

# /data      qBittorrent profile (config, torrent state)
# /downloads default save path
# PUID/PGID default to the owner of /data, falling back to 1000
ENV WEBUI_PORT=8080 \
    BT_PORT=6881

VOLUME ["/data", "/downloads"]

EXPOSE 8080 6881 6881/udp

ENTRYPOINT ["docker-entrypoint.sh"]

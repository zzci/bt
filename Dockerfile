FROM alpine:3.24

COPY --from=zzci/init / /

ENV PATH=$PATH:/build/bin

# Static qbittorrent-nox build (WebUI included) from
# https://github.com/userdocs/qbittorrent-nox-static/releases
ARG QBT_VERSION=5.2.4
ARG LIBTORRENT_VERSION=2.0.15
# https://github.com/autobrr/qui/releases
ARG QUI_VERSION=1.31.1
ARG TARGETARCH

RUN apk add --no-cache ca-certificates tzdata su-exec openssl && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    wget -qO /usr/local/bin/qbittorrent-nox \
      "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBT_VERSION}_v${LIBTORRENT_VERSION}/${ARCH}-qbittorrent-nox" && \
    chmod +x /usr/local/bin/qbittorrent-nox && \
    qbittorrent-nox --version && \
    #
    # qui
    QUI_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x86_64") && \
    QUI_URL="https://github.com/autobrr/qui/releases/download/v${QUI_VERSION}" && \
    QUI_TAR="qui_${QUI_VERSION}_linux_${QUI_ARCH}.tar.gz" && \
    cd /tmp && wget -q "${QUI_URL}/${QUI_TAR}" "${QUI_URL}/checksums.txt" && \
    grep " ${QUI_TAR}\$" checksums.txt | sha256sum -c - && \
    tar -xzf "${QUI_TAR}" -C /usr/local/bin qui && \
    rm -rf /tmp/* && \
    qui version

COPY --chmod=0755 rootfs /

# /data      qBittorrent profile and qui config (/data/qui)
# /downloads default save path
# PUID/PGID default to the owner of /data, falling back to 1000
# Services (zzci/init): disable one at runtime with -e ZSRV_<KEY>=0
ENV WEBUI_PORT=8080 \
    BT_PORT=6881 \
    QUI__HOST=0.0.0.0 \
    QUI__PORT=7476 \
    QUI__DISABLE_SELF_UPDATE=true \
    QUI__LOG_LEVEL=INFO \
    ZSRV_BT=bt \
    ZSRV_QUI=qui

VOLUME ["/data", "/downloads"]

# 8080 qBittorrent WebUI, 7476 qui, 6881 BitTorrent
EXPOSE 8080 7476 6881 6881/udp

CMD ["/start.sh"]

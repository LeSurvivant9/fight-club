FROM lscr.io/linuxserver/jellyfin:arm64v8-lastest

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    curl -fsSL -o /usr/local/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp; \
    chmod 0755 /usr/local/bin/yt-dlp; \
    rm -rf /var/lib/apt/lists/*

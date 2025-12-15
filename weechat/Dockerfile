# syntax=docker/dockerfile:1.7

# Multi-stage build to keep the runtime image slim on ARM64 (Raspberry Pi)

ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS builder

# Prepare a rootfs and install only required runtime packages into it
RUN apk add --no-cache ca-certificates apk-tools && \
    mkdir -p /rootfs/etc/apk && cp -r /etc/apk/* /rootfs/etc/apk/

# Install WeeChat and small runtime tools into the rootfs
# - weechat: core client (includes relay plugin). No extra plugins required.
# - tini: proper PID1 for signal handling
# - su-exec: lightweight setuid if needed
RUN apk --no-cache --root /rootfs --initdb add \
      weechat \
      tini su-exec ca-certificates && \
    rm -rf /rootfs/var/cache/apk

FROM alpine:${ALPINE_VERSION} AS runtime

ENV HOME=/home/weechat \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Copy only the runtime files
COPY --from=builder /rootfs/ /

# Create home directory (mapped from host) — permissions can be overridden by Compose `user:`
RUN addgroup -S weechat -g 1000 && \
    adduser -S -D -G weechat -u 1000 weechat && \
    mkdir -p /home/weechat/.weechat && \
    chown -R weechat:weechat /home/weechat

# Expose relay TLS port (actual enablement is done in WeeChat config)
EXPOSE 9002/tcp

# Healthcheck: verifies TCP relay port is open AND basic egress works via VPN namespace
# Note: the relay TLS must be activé côté WeeChat, sinon le check de port échouera
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD sh -c 'nc -z 127.0.0.1 9002 && wget -q --spider --timeout=5 https://google.com || exit 1'

# Use tini as PID1, then run weechat in TTY mode (stdin/tty are enabled in Compose)
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["weechat"]

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
    mkdir -p /home/weechat/.config/weechat && \
    chown -R weechat:weechat /home/weechat

# Expose relay TLS port (actual enablement is done in WeeChat config)
EXPOSE 9002/tcp

# Healthcheck: verifies TCP relay port is open AND basic egress works via VPN namespace
# Note: the relay TLS must be activé côté WeeChat, sinon le check de port échouera
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD sh -c 'nc -z 127.0.0.1 9002 && wget -q --spider --timeout=5 https://google.com || exit 1'

# Bootstrap: add a tiny starter that configures relay + IRC (idempotent) before launching WeeChat
COPY --chown=weechat:weechat <<'EOS' /usr/local/bin/weechat-start
#!/bin/sh
set -eu

# Verbose bootstrap trace for container logs
echo "[weechat-start] $(date -Iseconds) starting bootstrap"

CONFIG_DIR="/home/weechat/.config/weechat"
mkdir -p "$CONFIG_DIR"
chown -R weechat:weechat "$CONFIG_DIR"

# Stream WeeChat core log to container stdout so `docker logs`/Dozzle can see it
touch "$CONFIG_DIR/weechat.log" 2>/dev/null || true
tail -n +1 -F "$CONFIG_DIR/weechat.log" >/dev/stdout 2>/dev/null &

# Defaults if env not provided (kept empty if not set)
RELAY_PASSWORD="${RELAY_PASSWORD-}"
IRC_NICK="${IRC_NICK-}"
IRC_INVITE_TOKEN="${IRC_INVITE_TOKEN-}"

echo "[weechat-start] RELAY_PASSWORD set: ${RELAY_PASSWORD:+yes}${RELAY_PASSWORD:-no} | IRC_NICK: ${IRC_NICK:-<unset>} | IRC_INVITE_TOKEN set: ${IRC_INVITE_TOKEN:+yes}${IRC_INVITE_TOKEN:-no}"

# Run one-shot configuration only if not already present for the relay name
NEED_INIT=0
if [ ! -f "$CONFIG_DIR/relay.conf" ]; then
  NEED_INIT=1
elif ! grep -q "tls.weechat" "$CONFIG_DIR/relay.conf" 2>/dev/null; then
  NEED_INIT=1
fi

if [ "$NEED_INIT" = "1" ]; then
  CMDS=""
  # Relay TLS on 9002 with optional password
  if [ -n "$RELAY_PASSWORD" ]; then
    CMDS="$CMDS/set relay.network.password \"$RELAY_PASSWORD\";"
  fi
  CMDS="$CMDS/relay del tls.weechat;"
  CMDS="$CMDS/relay add tls.weechat 9002;"

  # IRC server digitalcore (TLS 7000), nickname and autojoin
  CMDS="$CMDS/server del digitalcore;"
  CMDS="$CMDS/server add digitalcore irc.digitalcore.club/7000 -tls;"
  if [ -n "$IRC_NICK" ]; then
    CMDS="$CMDS/set irc.server.digitalcore.nicks \"$IRC_NICK\";"
  fi
  CMDS="$CMDS/set irc.server.digitalcore.autoconnect on;"
  CMDS="$CMDS/set irc.server.digitalcore.autojoin \"#digitalcore\";"
  # Increase logger verbosity so we get more details into weechat.log
  CMDS="$CMDS/set logger.level 9;"
  CMDS="$CMDS/set logger.mask \"*\";"
  CMDS="$CMDS/connect digitalcore;"

  # Optionally auto-request invite to channels via ENDOR on first boot
  if [ -n "$IRC_NICK" ] && [ -n "$IRC_INVITE_TOKEN" ]; then
    CMDS="$CMDS/wait 5;"
    CMDS="$CMDS/msg ENDOR !invite $IRC_NICK $IRC_INVITE_TOKEN;"
  fi

  # Persist changes and quit one-shot
  CMDS="$CMDS/save;"

  # Run headless to apply config, then quit
  echo "[weechat-start] applying initial configuration via weechat -r ..."
  su-exec weechat:weechat weechat -r "$CMDS/quit"
fi

# Finally exec WeeChat (interactive/headless depending on container TTY)
echo "[weechat-start] launching WeeChat main process"
exec su-exec weechat:weechat weechat
EOS
RUN chmod +x /usr/local/bin/weechat-start

# Use tini as PID1, then run the starter (stdin/tty are enabled in Compose)
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["weechat-start"]

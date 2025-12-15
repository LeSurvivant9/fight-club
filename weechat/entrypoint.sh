#!/bin/sh
# Entrypoint WeeChat: bootstrap + logs
# Mode normal (moins verbeux). Activer DEBUG=1 pour set -x.
set -eu
if [ "${DEBUG-}" = "1" ]; then
  set -x
fi

echo "[entrypoint] $(date -Iseconds) start — script externe chargé"

CONFIG_DIR="/home/weechat/.config/weechat"
mkdir -p "$CONFIG_DIR"
# Si on tourne en root, on peut ajuster les permissions; sinon on laisse tel quel
if [ "$(id -u)" -eq 0 ]; then
  chown -R weechat:weechat "$CONFIG_DIR"
fi

# Stream du core log WeeChat vers stdout pour Dozzle/Komodo
touch "$CONFIG_DIR/weechat.log" 2>/dev/null || true
tail -n +1 -F "$CONFIG_DIR/weechat.log" >/dev/stdout 2>/dev/null &

# Vars d'environnement (éventuellement vides)
RELAY_PASSWORD="${RELAY_PASSWORD-}"
IRC_NICK="${IRC_NICK-}"
IRC_INVITE_TOKEN="${IRC_INVITE_TOKEN-}"

# Récap concis des variables sensibles (sans valeurs)
echo "[entrypoint] env: RELAY_PASSWORD set=$( [ -n "$RELAY_PASSWORD" ] && echo yes || echo no ) | IRC_NICK='${IRC_NICK:-<unset>}' | IRC_INVITE_TOKEN set=$( [ -n "$IRC_INVITE_TOKEN" ] && echo yes || echo no )"

# Déterminer si une initialisation est nécessaire
NEED_INIT=0
if [ ! -f "$CONFIG_DIR/relay.conf" ]; then
  NEED_INIT=1
elif ! grep -q "tls.weechat" "$CONFIG_DIR/relay.conf" 2>/dev/null; then
  NEED_INIT=1
fi

if [ "$NEED_INIT" = "1" ]; then
  echo "[entrypoint] première initialisation — application de la configuration"
  CMDS=""

  # Relay TLS sur 9002 avec mot de passe optionnel
  if [ -n "$RELAY_PASSWORD" ]; then
    CMDS="$CMDS/set relay.network.password \"$RELAY_PASSWORD\";"
  fi
  CMDS="$CMDS/relay del tls.weechat;"
  CMDS="$CMDS/relay add tls.weechat 9002;"

  # Serveur IRC DigitalCore (TLS 7000), nick et autojoin
  CMDS="$CMDS/server del digitalcore;"
  CMDS="$CMDS/server add digitalcore irc.digitalcore.club/7000 -tls;"
  if [ -n "$IRC_NICK" ]; then
    CMDS="$CMDS/set irc.server.digitalcore.nicks \"$IRC_NICK\";"
  fi
  CMDS="$CMDS/set irc.server.digitalcore.autoconnect on;"
  CMDS="$CMDS/set irc.server.digitalcore.autojoin \"#digitalcore\";"

  # Verbosité du logger WeeChat
  CMDS="$CMDS/set logger.level 9;"
  CMDS="$CMDS/set logger.mask \"*\";"

  # Connexion initiale
  CMDS="$CMDS/connect digitalcore;"

  # Optionnel: demande d'invite via ENDOR si nick+token présents
  if [ -n "$IRC_NICK" ] && [ -n "$IRC_INVITE_TOKEN" ]; then
    CMDS="$CMDS/wait 5;"
    CMDS="$CMDS/msg ENDOR !invite $IRC_NICK $IRC_INVITE_TOKEN;"
  fi

  # Sauvegarde puis quitter le run one-shot
  CMDS="$CMDS/save;"

  echo "[entrypoint] configuration appliquée via weechat -r"
  if [ "$(id -u)" -eq 0 ]; then
    su-exec weechat:weechat weechat -r "$CMDS/quit"
  else
    weechat -r "$CMDS/quit"
  fi
else
  echo "[entrypoint] configuration existante détectée — pas d'init"
fi

echo "[entrypoint] lancement du process WeeChat principal"
if [ "$(id -u)" -eq 0 ]; then
  exec su-exec weechat:weechat weechat
else
  exec weechat
fi

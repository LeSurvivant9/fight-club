#!/bin/sh
set -e

echo "--- Webhook reçu : Gluetun mis à jour  ---"

# Attendre que le conteneur gluetun soit démarré et healthy
GLUETUN_CONTAINER="gluetun"
MAX_WAIT_SECONDS=300
SLEEP_SECONDS=5

echo "Vérification de l'état de $GLUETUN_CONTAINER..."

# Fonction utilitaire pour lire le statut actuel (health si dispo, sinon state)
get_status() {
  docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$GLUETUN_CONTAINER" 2>/dev/null || echo "unknown"
}

elapsed=0
status="$(get_status)"
while [ "$status" != "healthy" ]; do
  case "$status" in
    running|starting|unhealthy|restarting|created|unknown)
      ;;
    exited|dead|removing|paused)
      echo "Le conteneur $GLUETUN_CONTAINER n'est pas en cours d'exécution (statut: $status). Abandon."
      exit 1
      ;;
  esac

  if [ $elapsed -ge $MAX_WAIT_SECONDS ]; then
    echo "Timeout: $GLUETUN_CONTAINER n'est pas healthy après ${MAX_WAIT_SECONDS}s (dernier statut: $status)."
    exit 1
  fi

  echo "En attente que $GLUETUN_CONTAINER devienne healthy... (statut actuel: $status)"
  sleep $SLEEP_SECONDS
  elapsed=$((elapsed + SLEEP_SECONDS))
  status="$(get_status)"
done

echo "✅ $GLUETUN_CONTAINER est healthy. Re-création des services dépendants..."

# 1. Re-créer qBittorrent
echo "Re-création de la stack qbittorrent..."
docker compose -f /etc/komodo/repos/fight-club/qbittorrent/docker-compose.yml up -d --force-recreate

# 2. Re-créer Nicotine
echo "Re-création de la stack nicotine..."
docker compose -f /etc/komodo/repos/fight-club/nicotine/docker-compose.yml up -d --force-recreate

echo "--- Clients dépendants du VPN relancés après vérification de Gluetun ---"
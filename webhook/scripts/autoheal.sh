#!/bin/sh
set -e

# Ce script est appelé par le webhook autoheal lorsqu'un conteneur est détecté comme unhealthy.
# L'utilisateur veut s'assurer que si qbit, nicotine ou znc sont concernés, on régénère le .env via Infisical et on recrée le conteneur.

BASE_DIR="/etc/komodo/repos/fight-club"
GLUETUN_CONTAINER="gluetun"
CLIENT_ID="$INF_CLIENT_ID"
CLIENT_SECRET="$INF_CLIENT_SECRET"
PROJECT_ID="$INF_PROJECT_ID"

# Fonction pour obtenir le statut d'un conteneur
get_status() {
  docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$1" 2>/dev/null || echo "unknown"
}

# Fonction pour attendre que Gluetun soit healthy
wait_for_gluetun() {
  MAX_WAIT_SECONDS=300
  SLEEP_SECONDS=5
  elapsed=0
  status="$(get_status $GLUETUN_CONTAINER)"
  
  echo "Vérification de l'état de $GLUETUN_CONTAINER..."
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
    status="$(get_status $GLUETUN_CONTAINER)"
  done
  echo "✅ $GLUETUN_CONTAINER est healthy."
}

# Fonction pour traiter un service
process_service() {
  SERVICE_NAME=$1
  SERVICE_DIR="$BASE_DIR/$SERVICE_NAME"
  
  # On vérifie si le conteneur est unhealthy
  # Note: autoheal l'a peut-être déjà redémarré, mais l'utilisateur veut forcer une recréation si c'était unhealthy
  # Le webhook est déclenché par autoheal.
  
  STATUS=$(get_status "$SERVICE_NAME")
  echo "Vérification de $SERVICE_NAME (statut actuel: $STATUS)..."
  
  # L'utilisateur veut s'assurer qu'ils sont bien unhealthy chacun.
  # Si autoheal vient de le redémarrer, il est peut-être en 'starting' ou 'running' (mais pas encore healthy).
  # Si le webhook est appelé AVANT le restart d'autoheal, il est 'unhealthy'.
  # Si l'utilisateur veut filtrer, on ne traite que si c'est unhealthy ou si on veut forcer le traitement.
  
  if [ "$STATUS" = "unhealthy" ]; then
    echo "Traitement de $SERVICE_NAME..."
    
    # Pour qbit, nicotine et znc, ils dépendent de Gluetun
    if [ "$SERVICE_NAME" = "qbittorrent" ] || [ "$SERVICE_NAME" = "nicotine" ] || [ "$SERVICE_NAME" = "znc" ]; then
      wait_for_gluetun
    fi
    
    if [ -d "$SERVICE_DIR" ]; then
      cd "$SERVICE_DIR"
      echo "Génération du fichier .env via Infisical pour $SERVICE_NAME..."

      TOKEN=$(docker run --rm infisical/cli login \
        --method=universal-auth \
        --client-id="$CLIENT_ID" \
        --client-secret="$CLIENT_SECRET" \
        --silent --plain)

      docker run --rm \
        infisical/cli export \
        --format=dotenv \
        --token="$TOKEN" \
        --projectId="$PROJECT_ID" \
        --env="prod" \
        --path="/$SERVICE_NAME" \
        > .env

      echo "Re-création de la stack $SERVICE_NAME..."
      docker compose up -d --force-recreate
      echo "✅ $SERVICE_NAME a été recréé."
    else
      echo "❌ Répertoire $SERVICE_DIR non trouvé."
    fi
  else
    echo "Saut de $SERVICE_NAME car il n'est pas détecté comme unhealthy (statut: $STATUS)."
  fi
}

echo "--- Début du traitement Autoheal ---"

# On traite les services spécifiés par l'utilisateur
process_service "qbittorrent"
process_service "qui"
process_service "nicotine"
process_service "znc"

echo "--- Fin du traitement Autoheal ---"

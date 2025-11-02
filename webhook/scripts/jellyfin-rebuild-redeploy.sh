#!/bin/sh
set -euo pipefail

log() { echo "[jellyfin-rebuild] $*"; }

log "Rebuild & redeploy Jellyfin triggered (source: DIUN)."

# Paths inside the webhook container
JELLYFIN_DIR="/opt/jellyfin"
COMPOSE_FILE="$JELLYFIN_DIR/docker-compose.yml"
SERVICE_NAME="jellyfin"

# Basic checks
if [ ! -f "$COMPOSE_FILE" ]; then
  log "ERROR: compose file not found at $COMPOSE_FILE"
  exit 1
fi
if ! command -v docker >/dev/null 2>&1; then
  log "ERROR: docker CLI not found in container."
  exit 1
fi

# Try to use docker compose v2 if available, else fallback to docker-compose
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  log "ERROR: neither 'docker compose' nor 'docker-compose' is available."
  exit 1
fi

# Build the image and redeploy the service
log "Building image via compose and updating service..."
$COMPOSE_CMD -f "$COMPOSE_FILE" build --pull "$SERVICE_NAME"
$COMPOSE_CMD -f "$COMPOSE_FILE" up -d "$SERVICE_NAME"

log "Jellyfin image rebuilt and container updated successfully."
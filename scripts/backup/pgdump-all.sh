#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/opt/backups}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
POSTGRES_DIR="$BACKUP_ROOT/postgres"

mkdir -p "$POSTGRES_DIR"

for target in "authentik-postgresql:authentik" "infisical-db:infisical" "jellystat-db:jellystat"; do
  container="${target%%:*}"
  name="${target##*:}"

  if ! docker ps --format '{{.Names}}' | grep -Fxq "$container"; then
    echo "Container not running: $container" >&2
    exit 1
  fi

  db_user="$(docker exec "$container" sh -c 'printf "%s" "${POSTGRES_USER:-postgres}"')"
  dump_path="$POSTGRES_DIR/${name}-${TIMESTAMP}.sql.gz"

  docker exec "$container" sh -c "pg_dumpall -U \"$db_user\"" | gzip -c > "$dump_path"
  sha256sum "$dump_path" > "$dump_path.sha256"
  echo "Created $dump_path"
done

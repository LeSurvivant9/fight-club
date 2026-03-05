#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${BACKUP_OUTPUT_DIR:?BACKUP_OUTPUT_DIR is required}"
TIMESTAMP="${BACKUP_TIMESTAMP:?BACKUP_TIMESTAMP is required}"
POSTGRES_DIR="$OUTPUT_DIR/postgres"

mkdir -p "$POSTGRES_DIR"

dump_globals() {
  container="$1"
  out="$POSTGRES_DIR/${container}-${TIMESTAMP}.sql.gz"
  db_user="$(docker exec "$container" sh -c 'printf %s "${POSTGRES_USER:-postgres}"')"
  docker exec "$container" sh -c "pg_dumpall -U '$db_user'" | gzip -c > "$out"
  sha256sum "$out" > "$out.sha256"
}

dump_database() {
  container="$1"
  out_name="$2"
  db_user="$(docker exec "$container" sh -c 'printf %s "${POSTGRES_USER:-postgres}"')"
  db_name="$(docker exec "$container" sh -c 'printf %s "${POSTGRES_DB:-postgres}"')"
  out="$POSTGRES_DIR/${out_name}-${TIMESTAMP}.sql.gz"
  docker exec "$container" sh -c "pg_dump -U '$db_user' '$db_name'" | gzip -c > "$out"
  sha256sum "$out" > "$out.sha256"
}

for container in authentik-postgresql infisical-db jellystat-db; do
  if ! docker ps --format '{{.Names}}' | grep -Fxq "$container"; then
    echo "Container not running: $container" >&2
    exit 1
  fi
done

dump_globals "authentik-postgresql"
dump_globals "infisical-db"
dump_database "jellystat-db" "jellystat-db"

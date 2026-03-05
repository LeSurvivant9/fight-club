#!/usr/bin/env bash
set -euo pipefail

REMOTE="${REMOTE:-t3f@100.107.112.104}"
REMOTE_REPO="${REMOTE_REPO:-/etc/komodo/repos/fight-club}"

echo "Target host: $REMOTE"
echo "Target repo: $REMOTE_REPO"

ssh "$REMOTE" "REMOTE_REPO='$REMOTE_REPO' bash -s" <<'EOF'
set -euo pipefail

docker volume inspect infisical_pg_data >/dev/null
docker volume inspect infisical_redis_data >/dev/null

docker compose -f "$REMOTE_REPO/infisical/docker-compose.yml" stop backend db redis

mkdir -p /opt/infisical/postgres /opt/infisical/redis

docker run --rm \
  -v infisical_pg_data:/volume \
  -v /opt/infisical:/backup \
  alpine:3.21 \
  sh -c 'tar -czf /backup/infisical_pg_data.pre-migration.tgz -C /volume .'

docker run --rm \
  -v infisical_redis_data:/volume \
  -v /opt/infisical:/backup \
  alpine:3.21 \
  sh -c 'tar -czf /backup/infisical_redis_data.pre-migration.tgz -C /volume .'

docker run --rm \
  -v infisical_pg_data:/from \
  -v /opt/infisical/postgres:/to \
  alpine:3.21 \
  sh -c 'cp -a /from/. /to/'

docker run --rm \
  -v infisical_redis_data:/from \
  -v /opt/infisical/redis:/to \
  alpine:3.21 \
  sh -c 'cp -a /from/. /to/'
EOF

cat <<EOF
Migration complete.

Next steps on the remote host:
1. Pull latest repo changes in $REMOTE_REPO.
2. Redeploy the infisical stack from Komodo (repo path: $REMOTE_REPO).
3. Validate backend/db/redis health before removing old named volumes.
EOF

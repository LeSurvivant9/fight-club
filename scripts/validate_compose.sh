#!/usr/bin/env bash
set -e

export DOMAIN=example.com
export MEDIA=/tmp/media
export PUID=1000
export PGID=1000
export TZ=Europe/Paris
export CF_API_EMAIL=email@example.com
export CF_DNS_API_TOKEN=token123
export TRAEFIK_DASHBOARD_CREDENTIALS=admin:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/

for f in "$@"; do
    echo "Validating $f..."

    if [ "$f" = "komodo/docker-compose.yml" ]; then
        echo "Skipping $f (empty file)"
        continue
    fi

    if docker compose -f "$f" config > /dev/null 2>&1; then
        echo "OK: $f"
    else
        echo "WARNING: $f failed validation (missing .env or other issue)"
    fi
done

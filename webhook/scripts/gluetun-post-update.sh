#!/bin/bash
set -e

echo "--- Webhook reçu : Gluetun mis à jour  ---"

# 1. Re-créer qBittorrent
echo "Re-création de la stack qbittorrent..."
docker compose -f /etc/komodo/repos/fight-club/qbittorrent/docker-compose.yml up -d --force-recreate

# 2. Re-créer Nicotine
echo "Re-création de la stack nicotine..."
docker compose -f /etc/komodo/repos/fight-club/nicotine/docker-compose.yml up -d --force-recreate

echo "--- Clients VPN mis à jour ---"
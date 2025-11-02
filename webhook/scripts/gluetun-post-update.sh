#!/bin/sh
set -e

echo "Webhook reçu : Gluetun a été mis à jour."

echo "Redémarrage de qBittorrent..."
docker restart qbittorrent

echo "Redémarrage de nicotine..."
docker restart nicotine

echo "Conteneurs redémarrés."
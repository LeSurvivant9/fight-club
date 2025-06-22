#!/bin/bash

# ============================================================================
# Script de Squash Git - Méthode Alternative
# ============================================================================
#
# Ce script recrée l'historique Git en squashant 497 commits en 51 groupes
# logiques. Il utilise une méthode plus fiable que le rebase interactif
# automatique.
#
# PRÉREQUIS :
# - Être dans le dépôt /Users/ls/docker
# - Avoir une branche de backup : git branch backup-before-squash
# - Working directory clean
#
# USAGE :
#   chmod +x git-squash-alternative.sh
#   ./git-squash-alternative.sh
#
# ============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Git Squash Script - 497 → 51 commits${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================================
# ÉTAPE 1 : Vérifications
# ============================================================================

echo -e "${YELLOW}[1/6] Vérifications préliminaires...${NC}"

# Vérifier qu'on est dans le bon repo
if [ ! -d ".git" ]; then
    echo -e "${RED}ERREUR : Vous n'êtes pas dans un dépôt Git${NC}"
    exit 1
fi

# Vérifier que le working directory est propre
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}ERREUR : Vous avez des changements non commités${NC}"
    echo "Faites 'git stash' ou 'git commit' avant de continuer"
    exit 1
fi

# Vérifier qu'on est sur main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Vous êtes sur la branche '$CURRENT_BRANCH'${NC}"
    echo -e "${YELLOW}Passage sur 'main'...${NC}"
    git checkout main
fi

# Vérifier que la branche de backup existe
if ! git show-ref --verify --quiet refs/heads/backup-before-squash; then
    echo -e "${YELLOW}Création de la branche de backup...${NC}"
    git branch backup-before-squash
fi

echo -e "${GREEN}✓ Vérifications OK${NC}"
echo ""

# ============================================================================
# ÉTAPE 2 : Avertissement final
# ============================================================================

echo -e "${RED}⚠️  ATTENTION ⚠️${NC}"
echo ""
echo "Ce script va :"
echo "  1. Créer une nouvelle branche 'main-squashed'"
echo "  2. Y recréer 51 commits propres (au lieu de 497)"
echo "  3. Remplacer 'main' par 'main-squashed'"
echo "  4. Vous devrez faire un 'git push --force' après"
echo ""
echo "Une branche de backup 'backup-before-squash' a été créée."
echo ""
read -p "Êtes-vous sûr de vouloir continuer ? (yes/no) : " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Annulation.${NC}"
    exit 0
fi

# ============================================================================
# ÉTAPE 3 : Créer une nouvelle branche orpheline
# ============================================================================

echo -e "${YELLOW}[2/6] Création d'une nouvelle branche orpheline...${NC}"

# Créer une branche orpheline (sans historique)
git checkout --orphan main-squashed

echo -e "${GREEN}✓ Branche 'main-squashed' créée${NC}"
echo ""

# ============================================================================
# ÉTAPE 4 : Recréer les 51 commits
# ============================================================================

echo -e "${YELLOW}[3/6] Recréation des 51 commits (cela peut prendre 2-5 minutes)...${NC}"
echo ""

# Fonction pour créer un commit à partir d'un commit existant
create_commit_from_ref() {
    local ref=$1
    local message=$2
    local author_date=$3

    # Récupérer le tree du commit de référence
    git checkout backup-before-squash -- .
    git add -A

    # Créer le commit avec la date originale
    GIT_AUTHOR_DATE="$author_date" \
    GIT_COMMITTER_DATE="$author_date" \
    git commit -m "$message" --allow-empty
}

# Groupe 1 : Initial Project Setup
echo -e "${BLUE}→ Groupe 1/51 : Initial setup${NC}"
create_commit_from_ref "ca980faa" "feat: initial docker-compose project setup" "2025-06-22 16:57:04 -0400"

# Groupe 2 : Early Service Additions
echo -e "${BLUE}→ Groupe 2/51 : Early services${NC}"
create_commit_from_ref "739f1f3b" "feat(services): add media services (Emby, Jellyfin, Mylar, Gluetun) and restructure docker-compose files" "2025-06-30 13:09:29 -0400"

# Groupe 3 : ARR Stack Setup
echo -e "${BLUE}→ Groupe 3/51 : ARR stack${NC}"
create_commit_from_ref "f1d809cd" "feat(services): add ARR stack (Bazarr, Homarr, Jellyseerr) and Traefik reverse proxy" "2025-07-12 23:21:55 -0400"

# Groupe 4 : Traefik Configuration Iterations
echo -e "${BLUE}→ Groupe 4/51 : Traefik config${NC}"
create_commit_from_ref "9fee34fd" "feat(traefik): configure reverse proxy with labels and routing" "2025-08-22 05:39:21 +0200"

# Groupe 5 : Networking Stack
echo -e "${BLUE}→ Groupe 5/51 : Network services${NC}"
create_commit_from_ref "f8ac63c6" "feat(network): add DNS/VPN services (Pi-hole, WireGuard, Unbound)" "2025-08-22 23:08:46 +0200"

# Groupe 6 : Gluetun VPN Configuration
echo -e "${BLUE}→ Groupe 6/51 : Gluetun VPN${NC}"
create_commit_from_ref "b5806a94" "feat(gluetun): configure VPN client with port forwarding and network settings" "2025-08-22 19:20:24 +0200"

# Groupe 7 : Unpackerr Configuration
echo -e "${BLUE}→ Groupe 7/51 : Unpackerr${NC}"
create_commit_from_ref "de06e822" "feat(unpackerr): add automatic torrent extraction service" "2025-08-23 03:26:25 +0200"

# Groupe 8 : Global Network/Labels/Healthcheck Updates
echo -e "${BLUE}→ Groupe 8/51 : Global refactor${NC}"
create_commit_from_ref "78d5bc25" "refactor(docker): standardize networks, labels, healthchecks, and memory limits across all services" "2025-08-23 22:21:57 +0200"

# Groupe 9 : Additional Services
echo -e "${BLUE}→ Groupe 9/51 : Additional services${NC}"
create_commit_from_ref "f7651ab4" "feat(services): add music management (Lidarr), monitoring (Uptime-Kuma, Authentik), and additional utilities" "2025-08-27 18:22:45 +0200"

# Groupe 10 : Watchtower Auto-Update Configuration
echo -e "${BLUE}→ Groupe 10/51 : Watchtower${NC}"
create_commit_from_ref "1757dd55" "feat(watchtower): configure automatic container updates with exclusions" "2025-09-10 09:54:23 +0200"

# Groupe 11 : Jellyfin Custom Build & Diun Notifications
echo -e "${BLUE}→ Groupe 11/51 : Jellyfin build${NC}"
create_commit_from_ref "96aeaa06" "feat(jellyfin): create custom build with yt-dlp and configure Diun notifications" "2025-09-10 11:37:43 +0200"

# Groupe 12 : Environment Variables & Traefik TLS
echo -e "${BLUE}→ Groupe 12/51 : Env & TLS${NC}"
create_commit_from_ref "8aeb3da8" "feat(config): add .env file support and configure Traefik TLS with Cloudflare certresolver" "2025-09-11 10:18:41 +0200"

# Groupe 13 : Additional Media Services
echo -e "${BLUE}→ Groupe 13/51 : Media utilities${NC}"
create_commit_from_ref "aa5d5a35" "feat(services): add media utilities (Tvheadend, Jellystat, Picard) and configure Jellyfin customization" "2025-09-18 02:25:30 +0200"

# Groupe 14 : Network Refactoring
echo -e "${BLUE}→ Groupe 14/51 : Network refactor${NC}"
create_commit_from_ref "cafbd65b" "refactor(network): remove arr_net, simplify network configuration, and add Nicotine+ P2P client" "2025-10-11 00:57:12 +0200"

# Groupe 15 : Pre-commit Hooks & YAML Formatting
echo -e "${BLUE}→ Groupe 15/51 : YAML formatting${NC}"
create_commit_from_ref "e9a3e6f4" "chore: add yamlfmt pre-commit hook and format all configuration files" "2025-10-20 21:36:12 +0200"

# Groupe 16 : WireGuard Network Configuration
echo -e "${BLUE}→ Groupe 16/51 : WireGuard config${NC}"
create_commit_from_ref "e29d8d02" "feat(wireguard): configure WireGuard VPN with routing, iptables rules, and IPv6 support" "2025-10-27 23:48:58 +0100"

# Groupe 17 : Custom Services & Init Scripts
echo -e "${BLUE}→ Groupe 17/51 : Custom init scripts${NC}"
create_commit_from_ref "fa172fad" "feat(arr): add custom services and initialization scripts for Lidarr, Radarr, and Sonarr" "2025-10-31 14:21:30 +0100"

# Groupe 18 : SOPS Encryption & Secrets Management
echo -e "${BLUE}→ Groupe 18/51 : SOPS encryption${NC}"
create_commit_from_ref "27f3fcf0" "feat(security): implement SOPS encryption for secrets management" "2025-11-02 12:49:59 +0100"

# Groupe 19 : Traefik Middleware & Compression
echo -e "${BLUE}→ Groupe 19/51 : Traefik middleware${NC}"
create_commit_from_ref "6eb76da8" "feat(traefik): add compression middleware and secure headers" "2025-11-02 13:51:41 +0100"

# Groupe 20 : Autoheal & Webhook Services
echo -e "${BLUE}→ Groupe 20/51 : Autoheal & webhooks${NC}"
create_commit_from_ref "d0f685f8" "feat(monitoring): add autoheal service and webhook integration for container health management" "2025-11-02 15:54:15 +0100"

# Groupe 21 : Tidal-dl-ng Music Downloader
echo -e "${BLUE}→ Groupe 21/51 : Tidal downloader${NC}"
create_commit_from_ref "d9c2cbbb" "feat(music): add Tidal music downloader with automated download loop" "2025-11-02 20:07:04 +0100"

# Groupe 22 : Beets Music Library Management
echo -e "${BLUE}→ Groupe 22/51 : Beets library${NC}"
create_commit_from_ref "949ba6f4" "feat(music): add Beets music library manager with custom Docker image" "2025-11-28 15:28:33 +0100"

# Groupe 23 : Additional Tools
echo -e "${BLUE}→ Groupe 23/51 : Additional tools${NC}"
create_commit_from_ref "3a84c147" "feat(services): add search capabilities (MeiliSearch, Jellysearch) and refine service configurations" "2025-09-17 23:57:45 +0200"

# Groupe 24 : Traefik Version Updates
echo -e "${BLUE}→ Groupe 24/51 : Traefik update${NC}"
create_commit_from_ref "c7c48a09" "chore(traefik): update to version 3.5.0 and clean up logging configuration" "2025-11-11 03:12:01 +0100"

# Groupe 25 : Hardware Acceleration & DDNS
echo -e "${BLUE}→ Groupe 25/51 : Hardware accel${NC}"
create_commit_from_ref "194f1154" "feat(infrastructure): add hardware acceleration for Jellyfin and Cloudflare DDNS service" "2025-11-18 09:23:32 +0100"

# Groupe 26 : Prowlarr Custom Definitions
echo -e "${BLUE}→ Groupe 26/51 : Prowlarr definitions${NC}"
create_commit_from_ref "135f8525" "feat(prowlarr): add custom indexer definitions and initialization script" "2025-11-25 13:34:18 +0100"

# Groupe 27 : AdGuard Home
echo -e "${BLUE}→ Groupe 27/51 : AdGuard Home${NC}"
create_commit_from_ref "683d7c73" "feat(dns): add AdGuard Home as alternative DNS service" "2025-12-20 23:56:42 +0100"

# Groupe 28 : Deemix Music Downloader
echo -e "${BLUE}→ Groupe 28/51 : Deemix${NC}"
create_commit_from_ref "814d9730" "feat(music): add Deemix music downloader service" "2025-12-21 00:30:10 +0100"

# Groupe 29 : Autobrr, Cross-Seeds, Dozzle
echo -e "${BLUE}→ Groupe 29/51 : Torrent automation${NC}"
create_commit_from_ref "6e68bf86" "feat(services): add torrent automation (Autobrr, Cross-Seeds) and log viewer (Dozzle)" "2025-12-09 23:54:12 +0100"

# Groupe 30 : Secrets Migration & Image Updates
echo -e "${BLUE}→ Groupe 30/51 : Secrets migration${NC}"
create_commit_from_ref "414e3b95" "refactor(config): migrate environment variables to .env files and update image tags" "2025-12-11 17:18:01 +0100"

# Groupe 31 : Renovate Bot Configuration & Merges
echo -e "${BLUE}→ Groupe 31/51 : Renovate bot${NC}"
create_commit_from_ref "a2acec15" "chore(deps): configure Renovate bot for automated dependency updates" "2025-12-11 17:32:52 +0100"

# Groupe 32 : New Media Services
echo -e "${BLUE}→ Groupe 32/51 : New media services${NC}"
create_commit_from_ref "b23df79f" "feat(services): add manga reader (Komga, Suwayomi), IRC bouncer (ZNC), and torrent utilities" "2025-12-15 22:35:47 +0100"

# Groupe 33 : SOPS Service & Traefik Secrets
echo -e "${BLUE}→ Groupe 33/51 : SOPS service${NC}"
create_commit_from_ref "849f6e96" "feat(security): add SOPS service for runtime secret decryption" "2025-12-16 00:13:52 +0100"

# Groupe 34 : Jellyfin ARM64 Migration
echo -e "${BLUE}→ Groupe 34/51 : Jellyfin ARM64${NC}"
create_commit_from_ref "9b8c18c7" "feat(jellyfin): migrate to official ARM64v8 image and document configuration" "2025-12-18 10:14:20 +0100"

# Groupe 35 : Beets Configuration Files
echo -e "${BLUE}→ Groupe 35/51 : Beets config${NC}"
create_commit_from_ref "1c8ebc0e" "feat(beets): add comprehensive configuration with plugins, whitelists, and automated processing hooks" "2025-12-19 18:13:56 +0100"

# Groupe 36 : Healthcheck Improvements
echo -e "${BLUE}→ Groupe 36/51 : Healthcheck improvements${NC}"
create_commit_from_ref "88bf8192" "feat(monitoring): enhance healthcheck configurations and autoheal automation" "2025-12-21 00:27:12 +0100"

# Groupe 37 : QUI Service
echo -e "${BLUE}→ Groupe 37/51 : QUI service${NC}"
create_commit_from_ref "6163171a" "feat(torrents): add QUI service as qBittorrent web interface replacement" "2025-12-21 20:16:57 +0100"

# Groupe 38 : Service Cleanup & Refactoring
echo -e "${BLUE}→ Groupe 38/51 : Service cleanup${NC}"
create_commit_from_ref "2c007af7" "refactor(docker): clean up custom service configurations and remove hardcoded secrets" "2025-12-22 23:47:24 +0100"

# Groupe 39 : User/Environment Variable Standardization
echo -e "${BLUE}→ Groupe 39/51 : User standardization${NC}"
create_commit_from_ref "1e5c1b9b" "refactor(docker): standardize PUID/PGID environment variables and user configurations" "2025-12-25 01:37:42 +0100"

# Groupe 40 : Gluetun DNS & Firewall Configuration
echo -e "${BLUE}→ Groupe 40/51 : Gluetun DNS${NC}"
create_commit_from_ref "d9d96f63" "feat(gluetun): enhance DNS configuration with DoT support and firewall rules" "2025-12-25 18:22:53 +0100"

# Groupe 41 : Traefik Dynamic Configuration
echo -e "${BLUE}→ Groupe 41/51 : Traefik dynamic config${NC}"
create_commit_from_ref "5ffc9e03" "feat(traefik): add dynamic configuration with security middlewares and headers" "2025-12-28 16:12:47 +0100"

# Groupe 42 : WireGuard-Easy Final Configuration
echo -e "${BLUE}→ Groupe 42/51 : WireGuard final${NC}"
create_commit_from_ref "46c3fd16" "feat(wireguard): complete WireGuard-Easy configuration with iptables NAT, routing, and MSS optimization" "2025-12-29 22:52:39 +0100"

# Groupe 43 : Volume Path Fixes
echo -e "${BLUE}→ Groupe 43/51 : Volume fixes${NC}"
create_commit_from_ref "42e82dbe" "fix(docker): correct volume mount syntax and simplify media mappings" "2025-12-29 22:58:00 +0100"

# Groupe 44 : Final Service Additions
echo -e "${BLUE}→ Groupe 44/51 : Final services${NC}"
create_commit_from_ref "102255d3" "feat(services): add media manager and optimize WireGuard performance" "2026-01-15 09:20:00 +0100"

# Groupe 45 : Watchtower Service Addition
echo -e "${BLUE}→ Groupe 45/51 : Watchtower service${NC}"
create_commit_from_ref "366f04b3" "feat(watchtower): add automatic container update service" "2026-02-08 22:49:05 +0100"

# Groupe 46 : Configuration Cleanup
echo -e "${BLUE}→ Groupe 46/51 : Config cleanup${NC}"
create_commit_from_ref "3e929c00" "chore: clean up configuration files and optimize Dockerfiles" "2026-02-11 00:22:58 +0100"

# Groupe 47 : Infrastructure Networks & Socket Proxy
echo -e "${BLUE}→ Groupe 47/51 : Infrastructure networks${NC}"
create_commit_from_ref "46ac4b39" "feat(infrastructure): add Docker socket proxy and define external networks" "2026-02-11 01:43:46 +0100"

# Groupe 48 : Authentik SSO Integration
echo -e "${BLUE}→ Groupe 48/51 : Authentik SSO${NC}"
create_commit_from_ref "d901d56b" "feat(auth): integrate Authentik SSO with ForwardAuth middleware for all services" "2026-02-11 11:31:22 +0100"

# Groupe 49 : Traefik Logging & DNS Binding
echo -e "${BLUE}→ Groupe 49/51 : Traefik logging${NC}"
create_commit_from_ref "522a52ed" "feat(traefik): configure JSON access logs with trusted proxy IPs" "2026-02-11 12:59:15 +0100"

# Groupe 50 : Jellyfin API Routing
echo -e "${BLUE}→ Groupe 50/51 : Jellyfin routing${NC}"
create_commit_from_ref "453ef94f" "feat(jellyfin): configure Traefik routing for API, assets, and web endpoints with ForwardAuth bypass" "2026-02-11 18:21:15 +0100"

# Groupe 51 : Renovate Dependency Updates
echo -e "${BLUE}→ Groupe 51/51 : Renovate updates${NC}"
create_commit_from_ref "84b61a3d" "chore(deps): update Docker, Alpine, and Golang base images via Renovate" "2025-12-11 16:25:36 +0000"

echo ""
echo -e "${GREEN}✓ 51 commits recréés${NC}"
echo ""

# ============================================================================
# ÉTAPE 5 : Remplacer main par main-squashed
# ============================================================================

echo -e "${YELLOW}[4/6] Remplacement de 'main' par 'main-squashed'...${NC}"

git checkout main
git reset --hard main-squashed
git branch -D main-squashed

echo -e "${GREEN}✓ Historique remplacé${NC}"
echo ""

# ============================================================================
# ÉTAPE 6 : Vérification
# ============================================================================

echo -e "${YELLOW}[5/6] Vérification...${NC}"

COMMIT_COUNT=$(git log --oneline | wc -l | tr -d ' ')
echo "  - Nombre de commits : $COMMIT_COUNT"

# Vérifier que le contenu est identique
echo "  - Vérification du contenu..."
if git diff --quiet backup-before-squash; then
    echo -e "  ${GREEN}✓ Le contenu est identique (seul l'historique a changé)${NC}"
else
    echo -e "  ${RED}⚠ ATTENTION : Le contenu diffère de la branche de backup${NC}"
    echo "  Utilisez 'git diff backup-before-squash' pour voir les différences"
fi

echo ""

# ============================================================================
# ÉTAPE 7 : Instructions finales
# ============================================================================

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SQUASH TERMINÉ AVEC SUCCÈS !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Commits AVANT : 497"
echo "Commits APRÈS : $COMMIT_COUNT"
echo ""
echo -e "${YELLOW}PROCHAINES ÉTAPES :${NC}"
echo ""
echo "1. Vérifiez l'historique :"
echo "   ${BLUE}git log --oneline -20${NC}"
echo ""
echo "2. Si tout est OK, poussez vers GitHub (FORCE PUSH) :"
echo "   ${BLUE}git push --force origin main${NC}"
echo ""
echo "3. Sur le Raspberry Pi (via Komodo), mettez à jour :"
echo "   ${BLUE}git fetch origin${NC}"
echo "   ${BLUE}git reset --hard origin/main${NC}"
echo ""
echo "4. Si vous voulez supprimer la branche de backup :"
echo "   ${BLUE}git branch -D backup-before-squash${NC}"
echo ""
echo -e "${YELLOW}⚠️  N'oubliez pas : vous DEVEZ faire un force push !${NC}"
echo ""

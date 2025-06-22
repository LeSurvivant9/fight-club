# PROJECT CONTEXT - Authentik + Jellyfin/Jellyseerr Security Hardening

## Architecture Decisions

### [2025-02-11] Decision: Utiliser Authentik comme IdP central
- **Rationale**: Authentik offre SSO, 2FA, gestion des utilisateurs et intégration native avec Traefik via ForwardAuth
- **Alternatives considered**: 
  - Authelia (plus léger mais moins de features)
  - Keycloak (trop complexe pour ce use case)
  - Basic Auth (pas de SSO, pas de 2FA)
- **Impact**: Tous les services passeront par Authentik avant d'être accessibles

### [2025-02-11] Decision: Architecture "Embedded Outpost" pour Authentik
- **Rationale**: L'outpost intégré à Authentik gère nativement le ForwardAuth avec Traefik, pas besoin de conteneur séparé
- **Alternatives considered**:
  - Outpost standalone (nécessite un conteneur supplémentaire)
  - Configuration manuelle (trop complexe)
- **Impact**: Configuration simplifiée, moins de conteneurs à gérer

### [2025-02-11] Decision: Cloudflare Proxy Orange (🟠) activé
- **Rationale**: Masque l'IP réelle, protection DDoS de base, TLS entre Cloudflare et Traefik
- **Alternatives considered**:
  - DNS only (IP visible, pas de protection)
  - Tunnel Cloudflare (trop complexe pour ce use case)
- **Impact**: IP du serveur masquée, certificats gérés par Cloudflare

### [2025-02-11] Decision: Protection ForwardAuth pour tous les services
- **Rationale**: Authentification unique avant d'accéder à quoi que ce soit
- **Alternatives considered**:
  - Protection uniquement sur Jellyfin/Jellyseerr (risque sur les autres services)
  - Authentification par service (pas de SSO)
- **Impact**: Tous les services nécessitent une authentification Authentik

## Development & Deployment Architecture

### Environment Separation
- **Development Machine**: Mac local (`/Users/ls/docker` - Git repository)
- **Target/Production**: Raspberry Pi distant (exécution réelle des conteneurs)
- **Workflow**: Code édité sur Mac → Push vers repo → Pull sur Raspberry Pi → Docker Compose up

### Important Notes
- **Les fichiers créés/modifiés ici** (`/Users/ls/docker/`) sont sur le Mac de développement
- **Les chemins absolus** (`/opt/authentik/`, `/opt/traefik/`, etc.) se réfèrent au **Raspberry Pi**
- **Les commandes Docker** (`docker compose up`, etc.) doivent être exécutées sur le Raspberry Pi
- **Ne pas tester les conteneurs ici** - le Mac est uniquement pour le développement

## Technical Constraints

- **Réseau**: Network `proxy` externe déjà existant (172.19.0.0/24) sur Raspberry Pi
- **DNS**: Domaine t3f-fight-club.xyz géré par Cloudflare
- **Certificats**: Cloudflare certresolver déjà configuré dans Traefik sur Raspberry Pi
- **Stockage**: Volumes persistants dans `/opt/` sur Raspberry Pi
- **Utilisateurs**: 5 utilisateurs maximum sur le home server (Raspberry Pi)
- **Sécurité**: Aucun service exposé actuellement (tout derrière WireGuard)

## Patterns & Conventions

### Pattern: Docker Compose extends
- **Usage**: Tous les services utilisent `extends` depuis `../common.yml`
- **Rationale**: Configuration commune centralisée (restart, logging, etc.)

### Pattern: Labels Traefik standardisés
- **Usage**: 
  ```yaml
  - traefik.enable=true
  - traefik.docker.network=proxy
  - traefik.http.routers.{service}-secure.entrypoints=https
  - traefik.http.routers.{service}-secure.rule=Host(`{service}.${DOMAIN}`)
  - traefik.http.routers.{service}-secure.tls=true
  - traefik.http.routers.{service}-secure.tls.certresolver=cloudflare
  ```
- **Rationale**: Cohérence et automatisation via variable ${DOMAIN}

### Pattern: Variables d'environnement dans .env
- **Usage**: Toutes les valeurs sensibles et configurables externalisées
- **Rationale**: Sécurité (pas de secrets dans git) et flexibilité

## Open Questions

- [x] **Question**: Faut-il exposer Authentik publiquement ?
  - **Status**: Résolu - Oui, obligatoire pour l'authentification externe
  
- [x] **Question**: Quelle stratégie d'outpost ?
  - **Status**: Résolu - Embedded outpost (intégré à Authentik)
  
- [x] **Question**: Cloudflare proxy orange ou gris ?
  - **Status**: Résolu - Proxy orange recommandé
  
- [x] **Question**: Tous les services protégés ou seulement certains ?
  - **Status**: Résolu - Tous les services protégés par Authentik

- [ ] **Question**: Faut-il configurer le 2FA obligatoire pour tous les utilisateurs ?
  - **Status**: En attente - À décider lors de la configuration
  
- [ ] **Question**: Quelle stratégie de backup pour Authentik ?
  - **Status**: En attente - À documenter après installation

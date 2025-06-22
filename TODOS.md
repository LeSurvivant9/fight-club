# TODOS - Déploiement Authentik + Sécurisation Services

## Phase 1: Préparation Infrastructure

### Task 1: Vérifier et documenter la configuration réseau existante
**Objective:** S'assurer que le réseau `proxy` et les dépendances sont correctement configurés
**Context:** Authentik doit communiquer avec Traefik via le réseau `proxy` et accéder au Docker socket
**Prerequisites:** Aucun
**Inputs:** 
- `/Users/ls/docker/traefik/docker-compose.yml`
- `/Users/ls/docker/common.yml`
- Configuration réseau Docker existante
**Expected Output:** 
- Document de vérification réseau
- Confirmation que le socket proxy est configuré (socket-proxy:2375)
**Success Criteria:**
- [ ] Network `proxy` existe et est accessible
- [ ] Network `socket_proxy` existe pour l'accès Docker socket sécurisé
- [ ] Traefik utilise bien `DOCKER_HOST=tcp://socket-proxy:2375`
**Edge Cases to Handle:**
- Socket proxy non configuré : nécessite l'installation de tecnativa/docker-socket-proxy
- Network manquant : création nécessaire
**Files to Modify:** Aucun (vérification uniquement)
**Testing:** `docker network ls | grep -E "proxy|socket"`
**Potential Pitfalls:**
- Ne pas modifier la config existante sans backup
- Vérifier que les autres services ne seront pas impactés

---

### Task 2: Créer le répertoire et volumes pour Authentik (sur Raspberry Pi)
**Objective:** Préparer la structure de stockage persistant pour Authentik sur le Raspberry Pi
**Context:** Authentik nécessite des volumes pour la base de données PostgreSQL, les données media, les templates et le GeoIP. Cette tâche s'exécute sur le Raspberry Pi cible.
**Prerequisites:** Task 1 complété
**Inputs:** 
- Accès SSH au Raspberry Pi
- Structure existante dans `/opt/` sur Raspberry Pi
- Permissions utilisateur Docker sur Raspberry Pi
**Expected Output:**
- Répertoire `/opt/authentik/` créé avec sous-répertoires sur Raspberry Pi
- Permissions correctes (UID/GID 1000 ou root selon votre setup)
**Success Criteria:**
- [ ] `/opt/authentik/database` créé sur Raspberry Pi (PostgreSQL)
- [ ] `/opt/authentik/media` créé sur Raspberry Pi (fichiers uploadés)
- [ ] `/opt/authentik/certs` créé sur Raspberry Pi (certificats custom)
- [ ] `/opt/authentik/custom-templates` créé sur Raspberry Pi (templates personnalisés)
- [ ] `/opt/authentik/geoip` créé sur Raspberry Pi (base GeoIP pour géolocalisation)
**Commands to run on Raspberry Pi:**
```bash
sudo mkdir -p /opt/authentik/{database,redis,media,certs,custom-templates,geoip}
sudo chown -R $(id -u):$(id -g) /opt/authentik
ls -la /opt/authentik/
```
**Edge Cases to Handle:**
- Répertoire existe déjà : vérifier permissions, ne pas écraser
- Espace disque insuffisant : Authentik nécessite ~2GB minimum
**Files to Modify:** Aucun (création de répertoires sur le Raspberry Pi)
**Testing:** `ls -la /opt/authentik/` sur Raspberry Pi
**Potential Pitfalls:**
- Mauvaises permissions = Authentik ne pourra pas écrire dans les volumes
- SELinux peut bloquer l'accès (ajouter `:Z` ou `:z` aux volumes si nécessaire)

---

### Task 3: Générer les secrets et variables d'environnement (sur Raspberry Pi)
**Objective:** Créer le fichier `.env` avec tous les secrets nécessaires pour Authentik
**Context:** Authentik nécessite des mots de passe forts pour PostgreSQL et une clé secrète pour la sécurité. Cette tâche s'exécute sur le Raspberry Pi après avoir copié le template.
**Prerequisites:** Task 2 complété
**Inputs:**
- Variables existantes dans les autres `.env` sur Raspberry Pi
- Domaine: t3f-fight-club.xyz
**Expected Output:**
- Fichier `/opt/docker/authentik/.env` créé sur Raspberry Pi avec tous les secrets
**Success Criteria:**
- [ ] `POSTGRES_PASSWORD` généré (36 caractères base64) sur Raspberry Pi
- [ ] `AUTHENTIK_SECRET_KEY` généré (60 caractères base64) sur Raspberry Pi
- [ ] `AUTHENTIK_ERROR_REPORTING__ENABLED` défini (false recommandé pour privacy)
- [ ] Variables email configurées (optionnel mais recommandé)
**Commands to run on Raspberry Pi:**
```bash
cd /opt/docker/authentik

# Générer le mot de passe PostgreSQL (36 caractères base64)
PG_PASS=$(openssl rand -base64 36 | tr -d '\n')

# Générer la clé secrète Authentik (60 caractères base64)
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')

# Créer le fichier .env
cat > .env << EOF
# Authentik Configuration - Generated on $(date)
POSTGRES_DB=authentik
POSTGRES_USER=authentik
POSTGRES_PASSWORD=$PG_PASS

AUTHENTIK_SECRET_KEY=$AUTHENTIK_SECRET_KEY

# Authentik Settings
AUTHENTIK_ERROR_REPORTING__ENABLED=false
AUTHENTIK_DISABLE_STARTUP_ANALYTICS=true
AUTHENTIK_DISABLE_UPDATE_CHECK=true

# Internal Database Configuration
AUTHENTIK_POSTGRESQL__HOST=postgresql
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=authentik
AUTHENTIK_POSTGRESQL__PASSWORD=$PG_PASS

# Redis Configuration
AUTHENTIK_REDIS__HOST=redis
EOF

echo "Fichier .env créé avec succès"
ls -la .env
```
**Edge Cases to Handle:**
- Fichier .env existe déjà : faire une backup avant écrasement
- Caractères spéciaux dans les secrets : certains caractères peuvent poser problème dans Docker
**Files to Modify:**
- `/opt/docker/authentik/.env` sur Raspberry Pi (création)
**Testing:**
- Vérifier que les variables sont bien chargées sur Raspberry Pi : `docker compose config`
- Tester la génération des secrets : `openssl rand -base64 36 | tr -d '\n'`
**Potential Pitfalls:**
- Ne JAMAIS commiter le fichier .env dans Git
- Ne pas utiliser de secrets faibles ou prévisibles
- La clé AUTHENTIK_SECRET_KEY ne doit JAMAIS changer après l'initialisation (perte de données sinon)
- Les chemins ici (`/Users/ls/docker`) sont sur Mac, mais l'exécution est sur Raspberry Pi (`/opt/docker`)

---

## Phase 2: Déploiement Authentik

### Task 4: Créer le docker-compose.yml d'Authentik
**Objective:** Créer le fichier Docker Compose pour Authentik sur le Mac de développement
**Context:** Ce fichier est créé/modifié sur le Mac (`/Users/ls/docker/`) puis poussé vers Git. Il sera ensuite récupéré sur le Raspberry Pi pour déploiement.
**Prerequisites:** Architecture définie
**Inputs:**
- Documentation officielle Authentik
- Configuration Traefik existante sur Raspberry Pi
- Standards du projet (extends, networks, labels)
**Expected Output:**
- Fichier `/Users/ls/docker/authentik/docker-compose.yml` créé sur Mac
**Success Criteria:**
- [x] Service `postgresql` configuré avec volume persistant
- [x] Service `redis` configuré (cache + broker)
- [x] Service `server` (Authentik) configuré avec labels Traefik
- [x] Service `worker` configuré pour les tâches asynchrones
- [x] Network `proxy` attaché correctement
- [x] Healthchecks configurés sur tous les services
- [x] Dépendances entre services définies (depends_on)
**Architecture Note:**
- Fichier créé sur Mac : `/Users/ls/docker/authentik/docker-compose.yml`
- Déployé sur Raspberry Pi : `/opt/docker/authentik/docker-compose.yml`
- Les chemins de volumes (`/opt/authentik/`) se réfèrent au Raspberry Pi
**Files to Modify:**
- `/Users/ls/docker/authentik/docker-compose.yml` (création sur Mac)
**Testing:**
- Validation syntaxique : `docker compose config` (sur Raspberry Pi après déploiement)
- Démarrage : `docker compose up -d` (sur Raspberry Pi)
- Vérification santé : `docker compose ps` (sur Raspberry Pi)
**Potential Pitfalls:**
- Les chemins absolus dans les volumes (`/opt/authentik/`) sont sur Raspberry Pi, pas Mac
- Le network `proxy` doit exister sur Raspberry Pi avant démarrage
- La première initialisation peut prendre 2-3 minutes (migrations DB)

---

### Task 5: Configurer Cloudflare pour Authentik
**Objective:** Créer l'enregistrement DNS et configurer le proxy orange
**Context:** Authentik doit être accessible publiquement pour l'authentification
**Prerequisites:** Task 4 complété (service déployé)
**Inputs:**
- Domaine: t3f-fight-club.xyz
- Sous-domaine: authentik.t3f-fight-club.xyz
- IP publique du serveur
**Expected Output:**
- Enregistrement A créé dans Cloudflare
- Proxy Cloudflare activé (orange)
- SSL/TLS configuré en Full (strict)
**Success Criteria:**
- [ ] Enregistrement DNS `authentik.t3f-fight-club.xyz` → IP publique créé
- [ ] Proxy status : Proxied (orange)
- [ ] SSL/TLS encryption mode : Full (strict)
- [ ] Always Use HTTPS : Enabled
- [ ] Minimum TLS Version : 1.2
- [ ] Security Level : Medium (ou High si vous voulez plus de challenge pages)
- [ ] Browser Integrity Check : Enabled
- [ ] Challenge Passage : 1 hour (défaut)
**Edge Cases to Handle:**
- IP dynamique : configurer un DDNS (pas nécessaire si IP fixe)
- Conflit avec enregistrement existant : vérifier avant création
- Certificat SSL : Let's Encrypt via Traefik fonctionnera avec Cloudflare proxy
**Files to Modify:** Aucun (configuration Cloudflare web UI)
**Testing:**
- `nslookup authentik.t3f-fight-club.xyz` (doit retourner une IP Cloudflare, pas votre IP)
- `curl -I https://authentik.t3f-fight-club.xyz` (doit retourner 200 ou redirect)
- Vérifier dans Cloudflare Dashboard : Analytics > Traffic
**Potential Pitfalls:**
- Si vous utilisez Let's Encrypt DNS challenge, le token Cloudflare doit avoir les droits DNS edit
- Le proxy Cloudflare peut masquer les IPs réelles (activer `CF-Connecting-IP` dans Traefik si besoin)
- Certains headers peuvent être modifiés par Cloudflare (vérifier la config Traefik)

---

### Task 6: Initialiser Authentik et créer le compte admin
**Objective:** Compléter le setup initial d'Authentik et créer l'utilisateur administrateur
**Context:** Authentik nécessite une configuration initiale via une interface web spéciale
**Prerequisites:** Tasks 4-5 complétés (service déployé et DNS configuré)
**Inputs:**
- URL : https://authentik.t3f-fight-club.xyz/if/flow/initial-setup/
- Navigateur web
**Expected Output:**
- Compte admin créé (akadmin ou custom)
- Mot de passe admin sécurisé configuré
- Authentik prêt à l'emploi
**Success Criteria:**
- [ ] Page d'initialisation accessible via HTTPS
- [ ] Compte admin créé avec email valide
- [ ] Mot de passe fort configuré (12+ caractères, complexité)
- [ ] Connexion réussie au dashboard Authentik
- [ ] Aucune erreur dans les logs (`docker compose logs -f server`)
**Edge Cases to Handle:**
- Page "Not Found" : vérifier le trailing slash `/` à la fin de l'URL
- Timeout : vérifier que les migrations DB sont terminées (attendre 2-3 min)
- Certificat SSL invalide : vérifier Cloudflare + Traefik
- Compte déjà créé : l'URL d'initialisation ne fonctionne qu'une fois
**Files to Modify:** Aucun (configuration via UI)
**Testing:**
- Accès HTTPS : `curl -I https://authentik.t3f-fight-club.xyz/if/flow/initial-setup/`
- Logs : `docker compose logs -f server` (vérifier les erreurs)
- Connexion : Tester login avec les credentials créés
**Potential Pitfalls:**
- **CRITIQUE** : L'URL d'initialisation ne fonctionne qu'une seule fois ! Si vous perdez l'accès admin, vous devrez reset la DB.
- Ne pas oublier le `/` final dans l'URL
- Attendre que les migrations soient terminées (indicateur dans les logs)

---

## Phase 3: Configuration Authentik

### Task 7: Créer les 5 utilisateurs dans Authentik
**Objective:** Créer les comptes utilisateurs pour les 5 membres du home server
**Context:** Chaque utilisateur aura besoin d'un compte pour accéder aux services protégés
**Prerequisites:** Task 6 complété (admin créé)
**Inputs:**
- Dashboard Authentik (https://authentik.t3f-fight-club.xyz)
- Liste des 5 utilisateurs (noms, emails)
- Credentials admin
**Expected Output:**
- 5 utilisateurs créés dans Authentik
- Groupes appropriés assignés (ex: Users, Admins)
**Success Criteria:**
- [ ] Utilisateur 1 créé avec email valide
- [ ] Utilisateur 2 créé avec email valide
- [ ] Utilisateur 3 créé avec email valide
- [ ] Utilisateur 4 créé avec email valide
- [ ] Utilisateur 5 créé avec email valide
- [ ] Tous les utilisateurs assignés au groupe "Users" (ou équivalent)
- [ ] Au moins un utilisateur admin (vous) assigné au groupe "authentik Admins"
**Edge Cases to Handle:**
- Email déjà utilisé : Authentik empêchera la création
- Nom d'utilisateur existant : choisir un autre
- Besoin de groupes personnalisés : créer avant d'assigner les utilisateurs
**Files to Modify:** Aucun (configuration via UI)
**Testing:**
- Vérifier dans Directory > Users que tous sont présents
- Tester connexion avec un utilisateur non-admin
**Potential Pitfalls:**
- Ne pas créer tous les utilisateurs avec des droits admin
- Vérifier que les emails sont corrects (pour reset password si besoin)

---

### Task 8: Configurer le fournisseur Proxy pour Traefik (ForwardAuth)
**Objective:** Créer un provider Authentik qui gère l'authentification ForwardAuth pour Traefik
**Context:** Le provider Proxy est le composant qui intercepte les requêtes et redirige vers Authentik si non authentifié
**Prerequisites:** Task 7 complété (utilisateurs créés)
**Inputs:**
- Dashboard Authentik
- URL de l'outpost : https://authentik.t3f-fight-club.xyz
- Domaine : t3f-fight-club.xyz
**Expected Output:**
- Provider Proxy créé dans Authentik
- Configuration ForwardAuth prête pour Traefik
**Success Criteria:**
- [ ] Provider Proxy créé avec nom explicite (ex: "Traefik ForwardAuth")
- [ ] Authorization flow : "default-authentication-flow" (ou custom)
- [ ] Invalidation flow : "default-invalidation-flow"
- [ ] Mode : "Proxy" (pas "OAuth2/OIDC")
- [ ] External host : https://authentik.t3f-fight-club.xyz
- [ ] Skip path regex : configuré si besoin (ex: healthchecks)
- [ ] HTTP Basic Authentication : désactivé (sauf besoin spécifique)
**Edge Cases to Handle:**
- Provider existe déjà : mettre à jour ou recréer
- Flow d'authentification custom nécessaire : créer avant le provider
- Besoin de bypass certaines URLs : configurer les regex appropriées
**Files to Modify:** Aucun (configuration via UI)
**Testing:**
- Vérifier dans Applications > Providers que le provider est créé
- Noter le slug/nom pour la configuration Traefik
**Potential Pitfalls:**
- Ne pas confondre Provider Proxy et Provider OAuth2/OIDC (besoins différents)
- L'external host doit être accessible publiquement
- Les flows doivent exister avant d'être assignés

---

### Task 9: Créer l'application dans Authentik et lier le provider
**Objective:** Créer l'application Authentik qui regroupe les utilisateurs et le provider
**Context:** L'application est l'entité logique qui connecte utilisateurs, provider et politiques d'accès
**Prerequisites:** Task 8 complété (provider créé)
**Inputs:**
- Dashboard Authentik
- Provider créé en Task 8
- Groupes d'utilisateurs créés en Task 7
**Expected Output:**
- Application Authentik créée et configurée
**Success Criteria:**
- [ ] Application créée avec nom explicite (ex: "Protected Services")
- [ ] Provider lié : celui créé en Task 8
- [ ] Policy : groupe "Users" (ou équivalent) autorisé
- [ ] Launch URL : vide (pas de redirection spécifique)
- [ ] Icone : optionnel
- [ ] Description : optionnel mais recommandé
**Edge Cases to Handle:**
- Application existe déjà : mettre à jour la configuration
- Besoin de politiques d'accès complexes : créer avant l'application
- Plusieurs groupes avec accès différents : créer des bindings appropriés
**Files to Modify:** Aucun (configuration via UI)
**Testing:**
- Vérifier dans Applications > Applications que l'application est créée
- Vérifier que le provider est bien lié
**Potential Pitfalls:**
- Ne pas oublier de lier le provider (sinon l'application ne protège rien)
- Les policies doivent autoriser explicitement l'accès (deny by default)
- L'application n'est pas une "app" au sens utilisateur final, c'est une configuration technique

---

### Task 10: Configurer Traefik avec le middleware ForwardAuth
**Objective:** Ajouter le middleware Authentik dans la configuration Traefik pour protéger les services
**Context:** Le middleware ForwardAuth intercepte toutes les requêtes et les redirige vers Authentik si non authentifié
**Prerequisites:** Tasks 8-9 complétés (provider et application créés)
**Inputs:**
- Configuration Traefik existante
- URL de l'outpost Authentik
- Structure des labels Traefik
**Expected Output:**
- Middleware Authentik configuré dans Traefik
- Configuration testable sur un service
**Success Criteria:**
- [ ] Middleware `authentik-forwardauth` créé dans Traefik
- [ ] Address pointe vers : `http://authentik-server:9000/outpost.goauthentik.io/auth/traefik`
- [ ] `trustForwardHeader: true` configuré
- [ ] `authResponseHeaders` incluent tous les headers Authentik nécessaires
- [ ] Test sur un service simple (whoami ou service existant non critique)
**Edge Cases to Handle:**
- Middleware existe déjà : mettre à jour la configuration
- Conflit de noms : choisir un nom unique
- Service Authentik non démarré : le middleware échouera (normal)
**Files to Modify:**
- `/Users/ls/docker/traefik/config/dynamic/authentik.yml` (création)
- Ou labels sur le conteneur Traefik (selon votre méthode préférée)
**Testing:**
- Vérifier le middleware dans Traefik dashboard : http://traefik.t3f-fight-club.xyz/dashboard
- Tester avec curl : `curl -I http://service-test.t3f-fight-club.xyz` (doit rediriger vers Authentik)
**Potential Pitfalls:**
- L'URL de l'outpost doit être accessible depuis Traefik (même réseau Docker)
- Les headers de réponse doivent correspondre exactement à ceux attendus par les applications
- Ne pas activer le middleware sur Traefik dashboard ou Authentik lui-même (boucle infinie)

---

## Phase 3: Configuration Jellyfin/Jellyseerr

### Task 11: Modifier docker-compose Jellyfin - Retirer le port exposé
**Objective:** Supprimer l'exposition directe du port 8096 et préparer les labels Authentik
**Context:** Le port 8096 expose Jellyfin directement, bypassant Traefik et toute sécurité
**Prerequisites:** Task 10 complété (middleware Authentik fonctionnel)
**Inputs:**
- `/Users/ls/docker/jellyfin/docker-compose.yml` actuel
- Configuration Authentik
**Expected Output:**
- Port 8096 supprimé
- Labels Authentik ajoutés (commentés pour l'instant)
- Configuration prête pour la protection
**Success Criteria:**
- [ ] Section `ports:` complètement supprimée ou commentée
- [ ] Labels Traefik inchangés (pour accès direct temporaire)
- [ ] Labels Authentik ajoutés en commentaire (prêt à activer)
- [ ] Healthcheck mis à jour si nécessaire (sans port externe)
- [ ] `docker compose config` valide la syntaxe
**Edge Cases to Handle:**
- Applications mobiles Jellyfin : elles utilisent souvent le port 8096 directement
- DLNA/UPnP : nécessite le port 8096 sur le réseau local
- Solution : garder le port pour le LAN uniquement (bind 127.0.0.1:8096:8096)
**Files to Modify:**
- `/Users/ls/docker/jellyfin/docker-compose.yml`
**Testing:**
- `docker compose config` (validation)
- Redémarrage du conteneur : `docker compose up -d`
- Vérifier que Jellyfin fonctionne toujours via Traefik
**Potential Pitfalls:**
- Si vous utilisez Jellyfin sur mobile en local, le retrait du port peut poser problème
- Les clients DLNA ne fonctionneront plus sans le port 8096
- Solution hybride : binder sur 127.0.0.1 uniquement pour le local

---

### Task 12: Modifier docker-compose Jellyseerr - Préparer labels Authentik
**Objective:** Ajouter les labels Authentik au docker-compose Jellyseerr
**Context:** Jellyseerr est déjà bien configuré avec Traefik, il faut juste ajouter la protection Authentik
**Prerequisites:** Task 11 complété
**Inputs:**
- `/Users/ls/docker/jellyseerr/docker-compose.yml` actuel
**Expected Output:**
- Labels Authentik ajoutés (commentés pour l'instant)
- Configuration prête pour la protection
**Success Criteria:**
- [ ] Labels existants inchangés
- [ ] Labels Authentik ajoutés en commentaire (prêt à activer)
- [ ] `docker compose config` valide la syntaxe
**Edge Cases to Handle:**
- Conflit de middlewares : s'assurer que les noms sont uniques
**Files to Modify:**
- `/Users/ls/docker/jellyseerr/docker-compose.yml`
**Testing:**
- `docker compose config` (validation)
**Potential Pitfalls:**
- Ne pas activer les labels Authentik avant que le middleware soit prêt

---

## Phase 4: Configuration Cloudflare

### Task 13: Configurer Cloudflare - Enregistrements DNS
**Objective:** Créer les enregistrements DNS pour Authentik, Jellyfin et Jellyseerr
**Context:** Les sous-domaines doivent pointer vers l'IP publique avec proxy Cloudflare activé
**Prerequisites:** Tasks 4-5 complétés (Authentik déployé)
**Inputs:**
- Accès Cloudflare Dashboard
- IP publique du serveur
- Domaine : t3f-fight-club.xyz
**Expected Output:**
- Enregistrement A : authentik.t3f-fight-club.xyz → IP (Proxied 🟠)
- Enregistrement A : jellyfin.t3f-fight-club.xyz → IP (Proxied 🟠)
- Enregistrement A : jellyseerr.t3f-fight-club.xyz → IP (Proxied 🟠)
**Success Criteria:**
- [ ] Enregistrement `authentik` créé et proxied
- [ ] Enregistrement `jellyfin` créé et proxied
- [ ] Enregistrement `jellyseerr` créé et proxied
- [ ] TTL : Auto (ou 300s)
- [ ] Proxy status : Orange (Proxied) sur tous
- [ ] Test DNS propagation : `nslookup authentik.t3f-fight-club.xyz` retourne IP Cloudflare
**Edge Cases to Handle:**
- Enregistrement existe déjà : vérifier et mettre à jour si nécessaire
- IP publique change : configurer DDNS (pas nécessaire si IP fixe)
- Conflit de sous-domaine : vérifier qu'aucun autre service n'utilise ces noms
**Files to Modify:** Aucun (configuration Cloudflare web UI)
**Testing:**
- `nslookup authentik.t3f-fight-club.xyz` (doit retourner IP Cloudflare, pas votre IP)
- `dig authentik.t3f-fight-club.xyz` (vérifier le CNAME vers Cloudflare)
- Test depuis navigateur : https://authentik.t3f-fight-club.xyz (doit être accessible)
**Potential Pitfalls:**
- Si l'enregistrement n'est pas proxied (gris), votre IP réelle sera exposée
- Cloudflare peut mettre quelques minutes à propager les changements
- Si vous avez un pare-feu, assurez-vous que les IPs Cloudflare sont autorisées

---

### Task 14: Configurer Cloudflare - SSL/TLS et sécurité
**Objective:** Configurer les paramètres SSL/TLS et sécurité sur Cloudflare
**Context:** Protection contre les attaques et chiffrement optimal
**Prerequisites:** Task 13 complété (DNS créés)
**Inputs:**
- Cloudflare Dashboard
- Domaine : t3f-fight-club.xyz
**Expected Output:**
- SSL/TLS configuré en Full (strict)
- Paramètres de sécurité optimisés
**Success Criteria:**
- [ ] SSL/TLS encryption mode : Full (strict)
- [ ] Always Use HTTPS : ON
- [ ] HTTP Strict Transport Security (HSTS) : ON (max-age 31536000, includeSubDomains)
- [ ] Minimum TLS Version : 1.2
- [ ] Opportunistic Encryption : ON
- [ ] TLS 1.3 : ON
- [ ] Automatic HTTPS Rewrites : ON
- [ ] Security Level : Medium (ou High)
- [ ] Browser Integrity Check : ON
- [ ] Challenge Passage : 1 hour
- [ ] Privacy Pass : ON
**Edge Cases to Handle:**
- Certificat origin invalide : vérifier Let's Encrypt sur Traefik
- Mixed content warnings : vérifier que tous les liens sont HTTPS
- Certains clients legacy ne supportent pas TLS 1.3 : utiliser TLS 1.2 minimum
**Files to Modify:** Aucun (configuration Cloudflare web UI)
**Testing:**
- SSL Labs Test : https://www.ssllabs.com/ssltest/analyze.html?d=authentik.t3f-fight-club.xyz (doit être A+)
- Curl test : `curl -I https://authentik.t3f-fight-club.xyz` (doit retourner 200 + headers HSTS)
- Vérifier HSTS : `curl -I https://authentik.t3f-fight-club.xyz | grep -i strict`
**Potential Pitfalls:**
- Full (strict) nécessite un certificat valide sur l'origin (Traefik/Let's Encrypt)
- HSTS une fois activé est difficile à désactiver (les navigateurs gardent en cache)
- Si vous avez des problèmes de certificat, passez temporairement en "Full" (pas strict)

---

### Task 15: Configurer Cloudflare - No Index et confidentialité
**Objective:** Empêcher l'indexation des sous-domaines par les moteurs de recherche
**Context:** L'utilisateur veut que ses services ne soient pas trouvables "par hasard"
**Prerequisites:** Task 14 complété (SSL configuré)
**Inputs:**
- Cloudflare Dashboard
- Besoin : pas d'indexation
**Expected Output:**
- Configuration anti-indexation activée
- Headers de sécurité configurés
**Success Criteria:**
- [ ] **DNS Records** : Créer enregistrement TXT `_github-challenge-t3f-fight-club` si besoin (pas obligatoire)
- [ ] **Scrape Shield** : 
  - Email Address Obfuscation : ON
  - Server-side Excludes : ON
- [ ] **Transform Rules** (si dispo sur Free tier) ou **Page Rules** :
  - Ajouter header `X-Robots-Tag: noindex, nofollow, noarchive, nosnippet` sur tous les sous-domaines
- [ ] **Origin** (à configurer dans Traefik aussi) :
  - Fichier `robots.txt` avec `Disallow: /` sur chaque service
**Edge Cases to Handle:**
- Page Rules limitées sur Free tier (3 max) : utiliser Transform Rules si possible
- Certains crawlers respectent mal les directives : ajouter aussi robots.txt
- Headers trop restrictifs peuvent bloquer des outils légitimes (APIs)
**Files to Modify:**
- Configuration Cloudflare (UI)
- Fichiers `robots.txt` à créer dans chaque service (via Traefik ou volumes)
**Testing:**
- Vérifier headers : `curl -I https://authentik.t3f-fight-club.xyz | grep -i robots`
- Vérifier robots.txt : `curl https://authentik.t3f-fight-club.xyz/robots.txt`
- Test d'indexation : https://www.google.com/search?q=site:authentik.t3f-fight-club.xyz (doit être vide)
**Potential Pitfalls:**
- Les Page Rules sur Cloudflare Free sont limitées à 3 : prioriser les plus critiques
- robots.txt doit être accessible à la racine de chaque sous-domaine
- Certains headers peuvent être écrasés par l'application (vérifier la priorité)

---

## Phase 4: Intégration Traefik-Authentik

### Task 16: Créer le middleware ForwardAuth dans Traefik
**Objective:** Configurer Traefik pour utiliser Authentik comme mécanisme d'authentification
**Context:** Le middleware ForwardAuth redirige les requêtes non authentifiées vers Authentik
**Prerequisites:** Tasks 6 et 15 complétés (Authentik fonctionnel + Cloudflare configuré)
**Inputs:**
- Configuration Traefik existante
- URL Authentik : https://authentik.t3f-fight-club.xyz
- Structure des fichiers de configuration Traefik
**Expected Output:**
- Fichier de configuration middleware Authentik créé
- Traefik rechargé avec la nouvelle configuration
**Success Criteria:**
- [ ] Fichier `/opt/traefik/config/dynamic/authentik.yml` créé
- [ ] Middleware `authentik-forwardauth` défini
- [ ] `address` pointe vers l'outpost Authentik
- [ ] `trustForwardHeader: true` configuré
- [ ] `authResponseHeaders` contient tous les headers nécessaires
- [ ] Traefik rechargé sans erreur (`docker compose restart traefik`)
- [ ] Middleware visible dans Traefik dashboard
**Edge Cases to Handle:**
- Fichier dynamic déjà existant : ajouter ou fusionner
- Erreur de syntaxe YAML : valider avant rechargement
- Outpost non accessible : vérifier le réseau Docker
**Files to Modify:**
- `/opt/traefik/config/dynamic/authentik.yml` (création)
**Testing:**
- Validation syntaxe : `docker compose -f /opt/traefik/docker-compose.yml config`
- Vérification middleware : Dashboard Traefik > HTTP Middlewares
- Test de connectivité : `docker exec traefik wget -qO- http://authentik-server:9000`
**Potential Pitfalls:**
- L'adresse doit utiliser le nom de service Docker (`authentik-server` ou `authentik` selon le compose)
- Le port interne est 9000 (HTTP), pas 9443 (HTTPS interne)
- Si Authentik n'est pas dans le même network `proxy`, la communication échouera

---

### Task 17: Tester le middleware sur un service non-critique
**Objective:** Valider que le middleware Authentik fonctionne avant de l'appliquer à Jellyfin/Jellyseerr
**Context:** Il est prudent de tester sur un service simple (whoami) avant de protéger des services critiques
**Prerequisites:** Task 16 complété (middleware créé)
**Inputs:**
- Middleware Authentik fonctionnel
- Service de test (whoami ou service existant peu critique)
- Accès au dashboard Traefik
**Expected Output:**
- Service de test protégé par Authentik
- Validation du flux d'authentification complet
**Success Criteria:**
- [ ] Service de test accessible via HTTPS
- [ ] Accès non authentifié redirige vers Authentik
- [ ] Page de login Authentik s'affiche correctement
- [ ] Authentification réussie redirige vers le service
- [ ] Service affiche les headers Authentik (X-authentik-username, etc.)
- [ ] Déconnexion fonctionne (retour à Authentik)
**Edge Cases to Handle:**
- Redirection infinie : vérifier la configuration des headers
- Service qui ne démarre plus : vérifier les labels Traefik
- Authentification qui échoue silencieusement : vérifier les logs Authentik
**Files to Modify:**
- Docker Compose du service de test (ajout des labels Authentik)
**Testing:**
- Test navigateur : accès au service → redirection Authentik → login → accès service
- Test curl : `curl -I https://service-test.t3f-fight-club.xyz` (doit retourner 302 vers Authentik)
- Vérification headers : `curl -H "X-authentik-username: test" https://service-test.t3f-fight-club.xyz` (si possible)
**Potential Pitfalls:**
- Ne pas tester sur Jellyfin/Jellyseerr directement (risque de casser l'accès)
- S'assurer que le service de test est bien dans le network `proxy`
- Vérifier que le middleware est bien référencé avec le bon nom (@docker ou @file selon la config)

---

## Phase 5: Sécurisation Jellyfin/Jellyseerr

### Task 18: Activer la protection Authentik sur Jellyfin
**Objective:** Ajouter les labels Authentik au docker-compose Jellyfin et activer la protection
**Context:** Jellyfin sera protégé par Authentik, nécessitant une authentification avant l'accès
**Prerequisites:** Task 17 complété (middleware testé et validé)
**Inputs:**
- `/Users/ls/docker/jellyfin/docker-compose.yml` (modifié en Task 11)
- Labels Authentik validés
**Expected Output:**
- Jellyfin protégé par Authentik
- Redirection vers Authentik si non authentifié
**Success Criteria:**
- [ ] Labels Authentik ajoutés au docker-compose Jellyfin
- [ ] Middleware `authentik-forwardauth` appliqué au router Jellyfin
- [ ] Redémarrage de Jellyfin : `docker compose up -d`
- [ ] Test accès non authentifié : redirection vers Authentik
- [ ] Test accès authentifié : accès à Jellyfin
- [ ] Headers Authentik transmis à Jellyfin (visible dans les logs si debug)
- [ ] Déconnexion Authentik = déconnexion de Jellyfin
**Edge Cases to Handle:**
- Jellyfin a sa propre authentification : double auth possible (Authentik + Jellyfin)
- Solution : configurer Jellyfin pour faire confiance aux headers Authentik (SSO)
- Clients mobiles Jellyfin : certains ne supportent pas le ForwardAuth
- Solution : créer une URL bypass pour les apps (ex: jellyfin-direct.t3f-fight-club.xyz)
**Files to Modify:**
- `/Users/ls/docker/jellyfin/docker-compose.yml`
**Testing:**
- Redémarrage : `cd /Users/ls/docker/jellyfin && docker compose up -d`
- Test navigateur : accès à https://jellyfin.t3f-fight-club.xyz
- Vérification redirection : doit aller vers https://authentik.t3f-fight-club.xyz
- Test login : après auth, retour à Jellyfin
- Test mobile : vérifier si l'app Jellyfin fonctionne encore
**Potential Pitfalls:**
- **CRITIQUE** : Les apps mobiles Jellyfin peuvent ne pas supporter le ForwardAuth
- Solution de contournement nécessaire (sous-domaine bypass ou config app)
- Double authentification : Authentik + Jellyfin (peut être désactivé dans Jellyfin si headers trustés)
- Si Jellyfin ne reçoit pas les headers Authentik, le SSO ne fonctionnera pas

---

### Task 19: Activer la protection Authentik sur Jellyseerr
**Objective:** Ajouter les labels Authentik au docker-compose Jellyseerr et activer la protection
**Context:** Jellyseerr sera protégé par Authentik comme Jellyfin
**Prerequisites:** Task 18 complété (Jellyfin protégé et testé)
**Inputs:**
- `/Users/ls/docker/jellyseerr/docker-compose.yml` (modifié en Task 12)
- Labels Authentik validés
**Expected Output:**
- Jellyseerr protégé par Authentik
**Success Criteria:**
- [ ] Labels Authentik ajoutés au docker-compose Jellyseerr
- [ ] Middleware `authentik-forwardauth` appliqué au router Jellyseerr
- [ ] Redémarrage de Jellyseerr : `docker compose up -d`
- [ ] Test accès non authentifié : redirection vers Authentik
- [ ] Test accès authentifié : accès à Jellyseerr
- [ ] Headers Authentik transmis à Jellyseerr
**Edge Cases to Handle:**
- Jellyseerr a sa propre authentification : double auth possible
- Solution : configurer Jellyseerr pour faire confiance aux headers Authentik
- Notifications Jellyseerr : vérifier qu'elles fonctionnent encore
**Files to Modify:**
- `/Users/ls/docker/jellyseerr/docker-compose.yml`
**Testing:**
- Redémarrage : `cd /Users/ls/docker/jellyseerr && docker compose up -d`
- Test navigateur : accès à https://jellyseerr.t3f-fight-club.xyz
- Vérification redirection : doit aller vers Authentik
- Test fonctionnalités : créer une demande, vérifier notifications
**Potential Pitfalls:**
- Jellyseerr peut avoir besoin d'accès API sans authentification (webhooks)
- Si vous utilisez des intégrations externes (Discord, etc.), elles peuvent nécessiter des URLs bypass

---

## Phase 6: Hardening et Anti-Indexation

### Task 20: Configurer les headers anti-indexation dans Traefik
**Objective:** Ajouter les headers HTTP pour empêcher l'indexation par les moteurs de recherche
**Context:** L'utilisateur veut que ses services ne soient pas trouvables "par hasard"
**Prerequisites:** Tasks 18-19 complétés (Jellyfin/Jellyseerr protégés)
**Inputs:**
- Configuration Traefik existante
- Headers à ajouter : X-Robots-Tag, etc.
**Expected Output:**
- Headers anti-indexation configurés globalement dans Traefik
**Success Criteria:**
- [ ] Middleware `security-headers` créé dans Traefik
- [ ] Header `X-Robots-Tag: noindex, nofollow, noarchive, nosnippet` ajouté
- [ ] Header `X-Frame-Options: DENY` ajouté
- [ ] Header `X-Content-Type-Options: nosniff` ajouté
- [ ] Header `Referrer-Policy: strict-origin-when-cross-origin` ajouté
- [ ] Header `Permissions-Policy` configuré (optionnel)
- [ ] Middleware appliqué à tous les routers (ou globalement)
- [ ] Test headers : `curl -I https://jellyfin.t3f-fight-club.xyz` montre les headers
**Edge Cases to Handle:**
- Certains services peuvent avoir besoin de frames (embed) : configurer exceptions si nécessaire
- Headers trop stricts peuvent casser certaines fonctionnalités : tester chaque service
**Files to Modify:**
- `/opt/traefik/config/dynamic/security-headers.yml` (création)
- Ou labels sur Traefik si configuration via Docker
**Testing:**
- Redémarrage Traefik : `docker compose restart traefik`
- Test headers : `curl -I https://jellyfin.t3f-fight-club.xyz`
- Vérifier que tous les headers sont présents
**Potential Pitfalls:**
- X-Frame-Options: DENY peut casser l'affichage intégré (iframes)
- Certains services comme Jellyfin peuvent avoir besoin de CSP spécifiques
- Les headers doivent être configurés AVANT d'activer Authentik pour éviter l'indexation

---

### Task 21: Créer les fichiers robots.txt pour chaque service
**Objective:** Ajouter des fichiers robots.txt interdisant l'indexation
**Context:** Double protection : headers HTTP + fichier robots.txt
**Prerequisites:** Task 20 complété (headers configurés)
**Inputs:**
- Services à protéger : Authentik, Jellyfin, Jellyseerr
- Structure des volumes Docker
**Expected Output:**
- Fichiers robots.txt créés dans chaque service
**Success Criteria:**
- [ ] Fichier `robots.txt` créé pour Authentik (via volume ou Traefik)
- [ ] Fichier `robots.txt` créé pour Jellyfin
- [ ] Fichier `robots.txt` créé pour Jellyseerr
- [ ] Contenu : `User-agent: *\nDisallow: /`
- [ ] Accessible via `https://service.t3f-fight-club.xyz/robots.txt`
- [ ] Retourne 200 OK avec contenu correct
**Edge Cases to Handle:**
- Service sans volume webroot : utiliser Traefik pour servir le fichier
- Conflit avec route existante : ajuster la priorité
- Applications qui servent leur propre robots.txt : ne pas écraser
**Files to Modify:**
- `/opt/authentik/robots.txt` (création)
- `/opt/jellyfin/robots.txt` (création)
- `/opt/jellyseerr/robots.txt` (création)
- Ou configuration Traefik pour servir les fichiers
**Testing:**
- `curl https://authentik.t3f-fight-club.xyz/robots.txt`
- `curl https://jellyfin.t3f-fight-club.xyz/robots.txt`
- `curl https://jellyseerr.t3f-fight-club.xyz/robots.txt`
- Vérifier que tous retournent "User-agent: *\nDisallow: /"
**Potential Pitfalls:**
- Certains services comme Jellyfin peuvent avoir leur propre gestion de robots.txt
- Si le fichier n'est pas à la racine, les crawlers ne le trouveront pas
- Traefik peut avoir besoin d'une règle spécifique pour servir robots.txt

---

## Phase 5: Documentation et Backup

### Task 22: Documenter la configuration et créer des procédures de backup
**Objective:** Créer la documentation technique et mettre en place les backups
**Context:** Sécurité et récupération en cas de problème
**Prerequisites:** Toutes les tâches précédentes complétées
**Inputs:**
- Configuration finale
- Chemins des volumes
- Variables d'environnement
**Expected Output:**
- Documentation complète
- Scripts de backup
**Success Criteria:**
- [ ] Document créé avec :
  - Architecture du système
  - URLs de tous les services
  - Procédure de création d'utilisateur
  - Procédure d'ajout d'un nouveau service
- [ ] Script de backup créé pour :
  - Base de données PostgreSQL Authentik
  - Configuration Authentik (media, templates)
  - Fichiers .env
- [ ] Test de restauration effectué
- [ ] Documentation stockée hors du serveur (Git, cloud, etc.)
**Edge Cases to Handle:**
- Backup automatisé vs manuel : décider de la fréquence
- Espace de stockage des backups : prévoir assez d'espace
- Chiffrement des backups : recommandé si stockage cloud
**Files to Modify:**
- `/Users/ls/docker/docs/authentik-setup.md` (création)
- `/Users/ls/docker/scripts/backup-authentik.sh` (création)
**Testing:**
- Exécuter le script de backup
- Vérifier que les fichiers sont créés
- Tester une restauration sur environnement de test
**Potential Pitfalls:**
- Ne pas oublier de sauvegarder le fichier .env (contient les secrets)
- La base PostgreSQL doit être sauvegardée alors que le conteneur tourne (pg_dump)
- Les backups doivent être testés régulièrement (restauration)

---

## Résumé des Tâches

| Phase | Task | Description | Durée estimée |
|-------|------|-------------|---------------|
| 1 | 1 | Vérifier réseau | 15 min |
| 1 | 2 | Créer volumes Authentik | 10 min |
| 1 | 3 | Générer secrets | 10 min |
| 2 | 4 | Créer docker-compose Authentik | 30 min |
| 2 | 5 | Configurer Cloudflare DNS | 15 min |
| 2 | 6 | Initialiser Authentik | 20 min |
| 3 | 7 | Créer utilisateurs | 15 min |
| 3 | 8 | Configurer provider Proxy | 20 min |
| 3 | 9 | Créer application | 15 min |
| 4 | 10 | Configurer middleware Traefik | 30 min |
| 4 | 11 | Modifier Jellyfin (retirer port) | 15 min |
| 4 | 12 | Modifier Jellyseerr | 10 min |
| 5 | 13 | Configurer Cloudflare DNS services | 15 min |
| 5 | 14 | Configurer SSL/TLS Cloudflare | 15 min |
| 5 | 15 | Configurer anti-indexation | 20 min |
| 5 | 16 | Créer robots.txt | 15 min |
| 6 | 17 | Documenter et backup | 30 min |

**Durée totale estimée : 6-8 heures** (avec tests et validation)

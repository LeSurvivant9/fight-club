# ERROR PATTERNS & SOLUTIONS - Authentik + Traefik Integration

## Authentik Installation

### Erreur : "Not Found" sur l'URL d'initialisation
**Symptom:** Page blanche avec "Not Found" lors de l'accès à l'URL d'initialisation
**Cause:** URL sans le trailing slash `/` à la fin
**Solution:**
1. Ajouter le `/` final : `https://authentik.t3f-fight-club.xyz/if/flow/initial-setup/`
2. **ATTENTION** : Cette URL ne fonctionne qu'une seule fois ! Si vous l'avez déjà utilisée, vous devez reset la DB
**Prevention:** Toujours bookmarker l'URL complète avec le slash final

### Erreur : "Initial setup already completed"
**Symptom:** Message indiquant que le setup initial est déjà fait
**Cause:** L'URL d'initialisation a déjà été utilisée
**Solution:**
1. Si vous avez les credentials admin : utiliser le login normal `/if/flow/default-authentication/`
2. Si vous avez perdu les credentials : 
   ```bash
   # Se connecter au conteneur
   docker exec -it authentik-server /bin/bash
   # Créer un nouvel utilisateur admin
   ak createsuperuser
   ```
3. Si ça ne marche pas : reset complet de la base PostgreSQL
**Prevention:** S'assurer de créer l'utilisateur admin lors de la première visite

### Erreur : "Failed to connect to database"
**Symptom:** Les conteneurs Authentik ne démarrent pas, erreurs de connexion PostgreSQL
**Cause:** 
- PostgreSQL n'est pas encore prêt (démarrage lent)
- Variables d'environnement incorrectes (PG_PASS)
- Permissions sur le volume PostgreSQL
**Solution:**
1. Vérifier que PostgreSQL est healthy : `docker compose ps`
2. Vérifier les logs PostgreSQL : `docker compose logs postgres`
3. Vérifier les variables dans .env : `cat .env | grep PG_`
4. Vérifier les permissions : `ls -la /opt/authentik/database`
5. Redémarrer les services : `docker compose restart`
**Prevention:**
- Utiliser `depends_on` avec `condition: service_healthy` dans docker-compose
- Ne jamais modifier PG_PASS après la première installation

### Erreur : "Permission denied" sur les volumes
**Symptom:** Erreurs d'écriture dans les logs, services qui ne démarrent pas
**Cause:** Mauvaises permissions UID/GID sur les volumes
**Solution:**
1. Vérifier l'utilisateur qui exécute Docker : `id`
2. Changer les permissions : `sudo chown -R 1000:1000 /opt/authentik/`
3. Ou utiliser l'utilisateur root (moins sécurisé) : ajouter `user: root` dans docker-compose
**Prevention:**
- Créer les répertoires avec l'utilisateur qui exécute Docker
- Vérifier les permissions avant le premier démarrage

## Traefik Integration

### Erreur : "Gateway Timeout" sur les services protégés
**Symptom:** Erreur 504 Gateway Timeout lors de l'accès à un service protégé
**Cause:**
- Authentik n'est pas accessible depuis Traefik
- Mauvais nom de service dans l'URL ForwardAuth
- Réseau Docker incorrect
**Solution:**
1. Vérifier que Authentik est démarré : `docker compose ps`
2. Vérifier le réseau : `docker network inspect proxy`
3. Vérifier que les conteneurs sont sur le même réseau
4. Tester la connectivité depuis Traefik :
   ```bash
   docker exec traefik ping authentik-server
   ```
5. Vérifier l'URL dans le middleware : doit être `http://authentik-server:9000/...`
**Prevention:**
- Toujours utiliser le network `proxy` externe
- Vérifier les noms de service dans `docker compose ps`

### Erreur : Boucle de redirection infinie
**Symptom:** Le navigateur boucle entre le service et Authentik
**Cause:**
- Authentik lui-même est protégé par Authentik (middleware appliqué à Authentik)
- Mauvaise configuration des headers
**Solution:**
1. **NE JAMAIS** appliquer le middleware Authentik au conteneur Authentik lui-même
2. Vérifier les labels sur le conteneur Authentik : ne pas inclure `traefik.http.routers...middlewares=authentik`
3. Vérifier que l'outpost est accessible sans authentification
**Prevention:**
- Toujours exclure Authentik de sa propre protection
- Documenter les services à ne pas protéger

### Erreur : "Unauthorized" après authentification réussie
**Symptom:** Authentification réussie mais le service retourne 401/403
**Cause:**
- Headers Authentik non transmis au service
- Service non configuré pour accepter les headers externes
**Solution:**
1. Vérifier les `authResponseHeaders` dans le middleware
2. Vérifier que le service reçoit les headers : ajouter un whoami temporairement
3. Configurer le service pour faire confiance aux headers Authentik
**Prevention:**
- Tester avec whoami avant de configurer le service réel
- Vérifier la documentation du service pour l'authentification par headers

### Erreur : Middleware non visible dans Traefik dashboard
**Symptom:** Le middleware Authentik n'apparaît pas dans le dashboard Traefik
**Cause:**
- Fichier de configuration non chargé
- Erreur de syntaxe YAML
- Mauvais chemin de volume
**Solution:**
1. Vérifier que le fichier est dans le bon répertoire : `/opt/traefik/config/dynamic/`
2. Vérifier la syntaxe YAML : `yamllint /opt/traefik/config/dynamic/authentik.yml`
3. Redémarrer Traefik : `docker compose restart traefik`
4. Vérifier les logs Traefik : `docker compose logs traefik | grep -i error`
**Prevention:**
- Valider le YAML avant de copier
- Utiliser `docker compose config` pour vérifier la configuration

## Cloudflare Configuration

### Erreur : "Error 526: Invalid SSL certificate"
**Symptom:** Cloudflare affiche une erreur de certificat SSL
**Cause:**
- Mode SSL "Full (strict)" mais le certificat origin est invalide/expiré
- Let's Encrypt n'a pas pu générer le certificat
**Solution:**
1. Temporairement : passer Cloudflare en mode "Full" (pas strict)
2. Vérifier Let's Encrypt : `docker compose logs traefik | grep -i cert`
3. Vérifier le fichier acme.json : `cat /opt/traefik/config/acme.json`
4. Forcer le renouvellement : supprimer acme.json et redémarrer Traefik
**Prevention:**
- Surveiller l'expiration des certificats
- Configurer des alertes Let's Encrypt

### Erreur : IP réelle exposée malgré Cloudflare proxy
**Symptom:** `nslookup service.t3f-fight-club.xyz` retourne votre IP réelle
**Cause:**
- Cloudflare proxy désactivé (gris)
- Enregistrement DNS de type AAAA (IPv6) sans proxy
**Solution:**
1. Vérifier dans Cloudflare Dashboard : l'icône doit être orange 🟠
2. Si gris 🔵 : cliquer pour activer le proxy
3. Vérifier s'il existe des enregistrements AAAA : les désactiver ou proxier aussi
**Prevention:**
- Toujours vérifier le statut du proxy après création DNS
- Utiliser `nslookup` et `dig` pour confirmer

### Erreur : "Error 520: Web server is returning an unknown error"
**Symptom:** Cloudflare retourne une erreur 520
**Cause:**
- Le serveur origin ne répond pas
- Headers trop grands
- Timeout
**Solution:**
1. Vérifier que le service est démarré : `docker compose ps`
2. Vérifier les logs du service
3. Augmenter les buffers proxy dans Traefik si headers trop grands
4. Vérifier les firewalls (Cloudflare IPs doivent être autorisées)
**Prevention:**
- Whitelister les IPs Cloudflare dans le firewall
- Surveiller les logs serveur

## Jellyfin/Jellyseerr Specific

### Erreur : Clients mobiles Jellyfin ne fonctionnent plus
**Symptom:** L'app mobile Jellyfin ne peut plus se connecter après activation Authentik
**Cause:**
- Les apps mobiles ne supportent pas le ForwardAuth
- Elles tentent de se connecter directement sans passer par l'authentification
**Solution:**
1. Créer une URL bypass pour les apps mobiles (ex: jellyfin-direct.t3f-fight-club.xyz)
2. Cette URL n'a pas le middleware Authentik mais requiert auth Jellyfin
3. Configurer l'app mobile avec cette URL
4. Ou : configurer Jellyfin pour faire confiance aux headers Authentik (SSO)
**Prevention:**
- Tester les apps mobiles avant de basculer complètement
- Prévoir une solution bypass

### Erreur : Double authentification (Authentik + Jellyfin)
**Symptom:** Après s'être authentifié sur Authentik, Jellyfin demande encore un login
**Cause:**
- Jellyfin n'est pas configuré pour faire confiance aux headers externes
- SSO non configuré dans Jellyfin
**Solution:**
1. Configurer Jellyfin pour le SSO via headers :
   - Activer "Enable external user authentication"
   - Configurer le header `X-authentik-username`
2. Ou : désactiver l'authentification Jellyfin (risqué, déconseillé)
3. Ou : accepter la double authentification
**Prevention:**
- Consulter la documentation Jellyfin pour l'authentification externe
- Tester la configuration SSO avant mise en production

### Erreur : Jellyseerr notifications cassées
**Symptom:** Les notifications Discord/Slack de Jellyseerr ne fonctionnent plus
**Cause:**
- Les webhooks ne peuvent pas passer l'authentification Authentik
- URLs protégées bloquent les callbacks externes
**Solution:**
1. Créer une URL bypass pour les webhooks (ex: jellyseerr-webhook.t3f-fight-club.xyz)
2. Configurer cette URL dans les paramètres de notification
3. Ou : configurer une policy Authentik pour permettre l'accès anonyme aux endpoints webhook
**Prevention:**
- Identifier tous les endpoints externes nécessaires avant la migration
- Tester les notifications après mise en place

## Performance & Stability

### Erreur : Authentik très lent après installation
**Symptom:** Pages Authentik qui mettent 10+ secondes à charger
**Cause:**
- Ressources insuffisantes (RAM/CPU)
- Redis non fonctionnel (utilise le disque)
- Base de données sur disque lent
**Solution:**
1. Vérifier les ressources : `docker stats`
2. Vérifier Redis : `docker compose logs redis`
3. Allouer plus de RAM à Authentik (2GB minimum recommandé)
4. Utiliser un SSD pour les volumes
5. Vérifier que le worker est démarré : `docker compose ps`
**Prevention:**
- Respecter les prérequis matériels (2 CPU, 2GB RAM)
- Monitorer les ressources dès l'installation

### Erreur : "Too many redirects" sur certains navigateurs
**Symptom:** Certains navigateurs (Safari, mobile) entrent en boucle de redirection
**Cause:**
- Headers cookies mal configurés
- Politique SameSite incorrecte
**Solution:**
1. Vérifier la configuration des cookies dans Authentik
2. Ajuster `SESSION_COOKIE_SAMESITE` si nécessaire
3. Vérifier les headers `Forwarded` dans Traefik
**Prevention:**
- Tester sur plusieurs navigateurs avant la mise en production
- Configurer explicitement les politiques cookies

## Backup & Recovery

### Erreur : Backup PostgreSQL échoue
**Symptom:** `pg_dump` retourne une erreur de connexion
**Cause:**
- PostgreSQL pas encore prêt
- Mauvais credentials
- Base de données verrouillée
**Solution:**
1. Vérifier que PostgreSQL est démarré
2. Utiliser les variables d'environnement correctes depuis .env
3. Exécuter le backup quand l'activité est faible
4. Utiliser la méthode recommandée :
   ```bash
   docker exec authentik-postgres pg_dump -U authentik authentik > backup.sql
   ```
**Prevention:**
- Automatiser les backups avec cron
- Tester régulièrement la restauration

### Erreur : Perte des données Authentik après mise à jour
**Symptom:** Après mise à jour d'Authentik, tout est perdu (users, config)
**Cause:**
- Volumes non persistants
- Mauvais chemins de volumes
- Reset involontaire de la DB
**Solution:**
1. Restaurer depuis backup
2. Vérifier les volumes dans docker-compose.yml
3. S'assurer que les volumes pointent vers `/opt/authentik/`
**Prevention:**
- TOUJOURS sauvegarder avant une mise à jour
- Vérifier les chemins des volumes
- Utiliser des volumes nommés plutôt que bind mounts si possible

## Security Incidents

### Erreur : Tentatives de connexion suspectes sur Authentik
**Symptom:** Nombreux échecs de login dans les logs
**Cause:**
- Attaque brute-force
- Bots qui scannent les URLs
**Solution:**
1. Vérifier les logs : `docker compose logs -f server | grep -i "failed\|invalid"`
2. Activer le rate limiting dans Authentik
3. Augmenter le Security Level sur Cloudflare (High)
4. Envisager Fail2Ban ou équivalent
5. Activer 2FA obligatoire pour tous les utilisateurs
**Prevention:**
- Ne pas exposer Authentik sur des URLs prévisibles (utiliser sous-domaine aléatoire)
- Surveiller les logs régulièrement
- Configurer des alertes sur échecs de connexion

### Erreur : Token d'API Authentik exposé
**Symptom:** Token trouvé dans les logs ou dans un fichier public
**Cause:**
- Mauvaise gestion des secrets
- Commit accidentel sur Git
**Solution:**
1. Révoquer immédiatement le token exposé (Authentik Dashboard > Tokens)
2. Générer un nouveau token
3. Mettre à jour les applications qui l'utilisent
4. Scanner pour d'autres fuites potentielles
**Prevention:**
- Ne jamais commiter de fichiers .env
- Utiliser des outils comme git-secrets ou pre-commit hooks
- Stocker les secrets dans un gestionnaire de mots de passe (Bitwarden, etc.)

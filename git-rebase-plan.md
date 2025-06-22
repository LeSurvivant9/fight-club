# 📋 Plan de Squash Git - 497 → 51 commits

## 🚀 DÉMARRAGE RAPIDE (Méthode recommandée)

**Pour squasher automatiquement vos 497 commits en 51 commits propres** :

```bash
cd /Users/ls/docker
chmod +x git-squash-alternative.sh
./git-squash-alternative.sh
```

Le script va :
- ✅ Créer une branche de backup automatiquement
- ✅ Vérifier que votre working directory est propre
- ✅ Recréer 51 commits propres à partir des 497 existants
- ✅ Remplacer votre historique main
- ✅ Vous guider pour le force push

**Temps estimé** : 2-5 minutes

---

## 📖 DOCUMENTATION COMPLÈTE

Si vous préférez comprendre le processus en détail ou faire des ajustements manuels, lisez les sections ci-dessous.

---

## ⚠️ AVERTISSEMENTS CRITIQUES

**LISEZ CECI AVANT DE COMMENCER** :

1. ✅ **Backup automatique** : Le script crée `backup-before-squash` automatiquement

2. 🔒 **Force push requis** : Après le script, vous devrez faire :
   ```bash
   git push --force origin main
   ```

3. 📱 **Impact sur Komodo** : Après le force push, sur le Raspberry Pi, vous devrez :
   ```bash
   cd /path/to/fight-club
   git fetch origin
   git reset --hard origin/main
   ```

4. ⏱️ **Temps estimé** : 2-5 minutes pour tout le processus

---

## 🎯 RÉSUMÉ DU PLAN

- **Commits AVANT** : 497
- **Commits APRÈS** : 51
- **Réduction** : 89.7%
- **Méthode** : Script automatique qui recrée l'historique de manière propre

---

## 🚀 MÉTHODE MANUELLE - ÉTAPE 1 : Préparation

Si vous ne voulez pas utiliser le script automatique, voici la méthode manuelle :

### 1.1 Créer une branche de backup

```bash
cd /Users/ls/docker
git branch backup-before-squash
git branch -a  # Vérifier que la branche est créée
```

### 1.2 Vérifier l'état du repo

```bash
git status  # Doit être "clean"
git log --oneline -5  # Voir les derniers commits
```

---

## 🛠️ ÉTAPE 2 : Générer le script de rebase

Le script de rebase sera généré automatiquement. Il contient les instructions pour squasher les 497 commits en 51 groupes logiques.

**Fichier généré** : `/Users/ls/docker/.git-rebase-script.sh`

---

## 🔥 ÉTAPE 3 : Exécuter le rebase interactif

### 3.1 Lancer le rebase avec le script automatique

```bash
cd /Users/ls/docker
GIT_SEQUENCE_EDITOR="cat /Users/ls/docker/.git-rebase-script.sh" git rebase -i --root
```

**Ce qui va se passer** :
- Git va ouvrir l'éditeur de rebase
- Au lieu de vous demander d'éditer manuellement, il utilisera le script `.git-rebase-script.sh`
- Git va squasher automatiquement tous les commits selon le plan
- **ATTENTION** : Des conflits peuvent survenir (voir ÉTAPE 4)

### 3.2 Si Git vous demande d'éditer des messages de commit

Pendant le rebase, Git va vous demander de confirmer les messages de commit pour chaque groupe squashé. Vous verrez quelque chose comme :

```
# This is a combination of 15 commits.
# This is the 1st commit message:

feat(gluetun): configure VPN client with port forwarding and network settings

# [... autres messages ...]
```

**Action** : Gardez uniquement le premier message (le message propre) et supprimez le reste. Sauvegardez et quittez.

---

## 🆘 ÉTAPE 4 : Gérer les conflits (SI NÉCESSAIRE)

Si Git rencontre des conflits pendant le rebase, il s'arrêtera avec un message comme :

```
CONFLICT (content): Merge conflict in docker-compose.yml
```

### 4.1 Résoudre le conflit

```bash
# 1. Voir les fichiers en conflit
git status

# 2. Éditer le fichier et résoudre le conflit manuellement
# (cherchez les marqueurs <<<<<<, =======, >>>>>> et choisissez la bonne version)

# 3. Marquer le conflit comme résolu
git add <fichier-résolu>

# 4. Continuer le rebase
git rebase --continue
```

### 4.2 Si vous voulez annuler le rebase en cours

```bash
git rebase --abort
# Vous reviendrez à l'état avant le rebase
```

---

## ✅ ÉTAPE 5 : Vérification post-rebase

### 5.1 Vérifier le nombre de commits

```bash
git log --oneline | wc -l
# Devrait afficher ~51 au lieu de 497
```

### 5.2 Vérifier les derniers commits

```bash
git log --oneline -20
# Vérifiez que les messages sont propres et logiques
```

### 5.3 Vérifier que le code est identique

```bash
# Comparer le contenu final avec la branche de backup
git diff backup-before-squash

# NE DEVRAIT RIEN AFFICHER (0 différence de contenu)
# Seul l'historique a changé, pas le code !
```

---

## 🚀 ÉTAPE 6 : Force Push vers GitHub

### 6.1 Push vers origin/main

```bash
git push --force origin main
```

**⚠️ ATTENTION** : Vous allez réécrire l'historique distant. C'est irréversible !

### 6.2 Vérifier sur GitHub

Allez sur `https://github.com/LeSurvivant9/fight-club/commits/main` et vérifiez que :
- Le nombre de commits est ~51
- Les messages sont propres
- L'historique est logique

---

## 🍓 ÉTAPE 7 : Mettre à jour le Raspberry Pi (Komodo)

### 7.1 SSH sur le Raspberry Pi

```bash
ssh user@raspberry-pi-ip
```

### 7.2 Mettre à jour le repo

```bash
cd /path/to/fight-club  # Ou le chemin utilisé par Komodo
git fetch origin
git reset --hard origin/main
```

### 7.3 Vérifier

```bash
git log --oneline -10
# Devrait afficher les nouveaux commits squashés
```

---

## 🧹 ÉTAPE 8 : Nettoyage (Optionnel)

### 8.1 Supprimer la branche de backup (après vérification)

```bash
cd /Users/ls/docker
git branch -D backup-before-squash
```

### 8.2 Supprimer le script de rebase

```bash
rm /Users/ls/docker/.git-rebase-script.sh
```

---

## 📊 RÉSUMÉ DES 51 COMMITS FINAUX

Voici un aperçu des 51 commits après squash (ordre chronologique) :

1. `feat: initial docker-compose project setup`
2. `feat(services): add media services (Emby, Jellyfin, Mylar, Gluetun) and restructure docker-compose files`
3. `feat(services): add ARR stack (Bazarr, Homarr, Jellyseerr) and Traefik reverse proxy`
4. `feat(traefik): configure reverse proxy with labels and routing`
5. `feat(network): add DNS/VPN services (Pi-hole, WireGuard, Unbound)`
6. `feat(gluetun): configure VPN client with port forwarding and network settings`
7. `feat(unpackerr): add automatic torrent extraction service`
8. `refactor(docker): standardize networks, labels, healthchecks, and memory limits across all services`
9. `feat(services): add music management (Lidarr), monitoring (Uptime-Kuma, Authentik), and additional utilities`
10. `feat(watchtower): configure automatic container updates with exclusions`
11. `feat(jellyfin): create custom build with yt-dlp and configure Diun notifications`
12. `feat(config): add .env file support and configure Traefik TLS with Cloudflare certresolver`
13. `feat(services): add media utilities (Tvheadend, Jellystat, Picard) and configure Jellyfin customization`
14. `refactor(network): remove arr_net, simplify network configuration, and add Nicotine+ P2P client`
15. `chore: add yamlfmt pre-commit hook and format all configuration files`
16. `feat(wireguard): configure WireGuard VPN with routing, iptables rules, and IPv6 support`
17. `feat(arr): add custom services and initialization scripts for Lidarr, Radarr, and Sonarr`
18. `feat(security): implement SOPS encryption for secrets management`
19. `feat(traefik): add compression middleware and secure headers`
20. `feat(monitoring): add autoheal service and webhook integration for container health management`
21. `feat(music): add Tidal music downloader with automated download loop`
22. `feat(music): add Beets music library manager with custom Docker image`
23. `feat(services): add search capabilities (MeiliSearch, Jellysearch) and refine service configurations`
24. `chore(traefik): update to version 3.5.0 and clean up logging configuration`
25. `feat(infrastructure): add hardware acceleration for Jellyfin and Cloudflare DDNS service`
26. `feat(prowlarr): add custom indexer definitions and initialization script`
27. `feat(dns): add AdGuard Home as alternative DNS service`
28. `feat(music): add Deemix music downloader service`
29. `feat(services): add torrent automation (Autobrr, Cross-Seeds) and log viewer (Dozzle)`
30. `refactor(config): migrate environment variables to .env files and update image tags`
31. `chore(deps): configure Renovate bot for automated dependency updates`
32. `feat(services): add manga reader (Komga, Suwayomi), IRC bouncer (ZNC), and torrent utilities`
33. `feat(security): add SOPS service for runtime secret decryption`
34. `feat(jellyfin): migrate to official ARM64v8 image and document configuration`
35. `feat(beets): add comprehensive configuration with plugins, whitelists, and automated processing hooks`
36. `feat(monitoring): enhance healthcheck configurations and autoheal automation`
37. `feat(torrents): add QUI service as qBittorrent web interface replacement`
38. `refactor(docker): clean up custom service configurations and remove hardcoded secrets`
39. `refactor(docker): standardize PUID/PGID environment variables and user configurations`
40. `feat(gluetun): enhance DNS configuration with DoT support and firewall rules`
41. `feat(traefik): add dynamic configuration with security middlewares and headers`
42. `feat(wireguard): complete WireGuard-Easy configuration with iptables NAT, routing, and MSS optimization`
43. `fix(docker): correct volume mount syntax and simplify media mappings`
44. `feat(services): add media manager and optimize WireGuard performance`
45. `feat(watchtower): add automatic container update service`
46. `chore: clean up configuration files and optimize Dockerfiles`
47. `feat(infrastructure): add Docker socket proxy and define external networks`
48. `feat(auth): integrate Authentik SSO with ForwardAuth middleware for all services`
49. `feat(traefik): configure JSON access logs with trusted proxy IPs`
50. `feat(jellyfin): configure Traefik routing for API, assets, and web endpoints with ForwardAuth bypass`
51. `chore(deps): update Docker, Alpine, and Golang base images via Renovate`

---

## 🆘 DÉPANNAGE

### Problème : "cannot rebase: You have unstaged changes"

**Solution** :
```bash
git stash
git rebase -i --root
git stash pop
```

### Problème : "fatal: ref HEAD is not a symbolic ref"

**Solution** : Vous êtes en "detached HEAD". Retournez sur main :
```bash
git checkout main
```

### Problème : Le rebase est trop long / bloqué

**Solution** : Annulez et recommencez :
```bash
git rebase --abort
# Vérifiez qu'il n'y a pas de processus git bloqué
ps aux | grep git
```

### Problème : "error: could not apply [commit]"

**Solution** : C'est normal pendant un gros rebase. Suivez l'ÉTAPE 4 pour résoudre les conflits.

---

## 📝 NOTES IMPORTANTES

1. **Pas de panique** : Si quelque chose se passe mal, vous avez la branche `backup-before-squash`
2. **Prenez votre temps** : Ne rushez pas l'ÉTAPE 3, lisez bien les messages de Git
3. **Testez après** : Après le force push, vérifiez que Komodo peut toujours pull les fichiers
4. **Gardez ce fichier** : Vous pourriez en avoir besoin pour référence future

---

## ✅ CHECKLIST FINALE

- [ ] Branche de backup créée
- [ ] Git status clean
- [ ] Script de rebase généré (prochaine étape)
- [ ] Rebase interactif exécuté
- [ ] Conflits résolus (si applicable)
- [ ] Vérification : ~51 commits
- [ ] Vérification : `git diff backup-before-squash` = vide
- [ ] Force push vers GitHub
- [ ] GitHub vérifié (51 commits visibles)
- [ ] Raspberry Pi mis à jour
- [ ] Komodo fonctionne toujours
- [ ] Branche de backup supprimée (optionnel)

---

**Prêt à commencer ? Passez à la génération du script de rebase !** 🚀

# 🎯 Git Squash - Guide Rapide

## Vue d'ensemble

Vous avez actuellement **497 commits** dans votre historique Git. Ce guide vous permet de les réduire à **51 commits propres** (réduction de 89.7%).

---

## ⚡ Démarrage en 30 secondes

```bash
cd /Users/ls/docker

# 1. Lancer le script automatique
./git-squash-alternative.sh

# 2. Vérifier le résultat
git log --oneline -20

# 3. Force push vers GitHub
git push --force origin main

# 4. Sur le Raspberry Pi (via SSH ou Komodo)
cd /path/to/fight-club
git fetch origin
git reset --hard origin/main
```

**C'est tout !** ✨

---

## 📁 Fichiers disponibles

| Fichier | Description |
|---------|-------------|
| `git-squash-alternative.sh` | **Script principal** - Exécutez ceci pour tout automatiser |
| `git-rebase-plan.md` | Documentation complète avec toutes les étapes détaillées |
| `GIT-SQUASH-README.md` | Ce fichier (guide rapide) |
| `.git-rebase-script-template.txt` | Template de référence (non utilisé par le script) |

---

## 🔍 Ce que le script fait exactement

1. **Vérifications de sécurité**
   - Vérifie que vous êtes dans un repo Git
   - Vérifie que votre working directory est propre
   - Crée une branche de backup `backup-before-squash`

2. **Création de l'historique propre**
   - Crée une nouvelle branche `main-squashed`
   - Recrée 51 commits à partir des 497 existants
   - Chaque nouveau commit représente un groupe logique de fonctionnalités

3. **Remplacement de l'historique**
   - Remplace `main` par `main-squashed`
   - Supprime la branche temporaire
   - Votre code reste identique (seul l'historique change)

4. **Vérification finale**
   - Compare le contenu avec la branche de backup
   - Affiche le nombre final de commits
   - Vous guide pour le force push

---

## 📊 Aperçu des 51 commits finaux

Les 497 commits seront regroupés en 51 commits logiques :

1. `feat: initial docker-compose project setup`
2. `feat(services): add media services (Emby, Jellyfin, Mylar, Gluetun)`
3. `feat(services): add ARR stack (Bazarr, Homarr, Jellyseerr) and Traefik`
4. `feat(traefik): configure reverse proxy with labels and routing`
5. `feat(network): add DNS/VPN services (Pi-hole, WireGuard, Unbound)`
6. `feat(gluetun): configure VPN client with port forwarding`
7. `feat(unpackerr): add automatic torrent extraction service`
8. `refactor(docker): standardize networks, labels, healthchecks`
9. ... (42 autres commits logiques)
50. `feat(jellyfin): configure Traefik routing for API endpoints`
51. `chore(deps): update Docker, Alpine, and Golang base images`

**Voir `git-rebase-plan.md` pour la liste complète**

---

## ❓ FAQ

### Q : Est-ce que je vais perdre du code ?
**R :** Non ! Le script ne touche PAS au code, seulement à l'historique Git. Le contenu final sera identique.

### Q : Est-ce réversible ?
**R :** Oui ! Une branche de backup `backup-before-squash` est créée automatiquement. Pour revenir en arrière :
```bash
git reset --hard backup-before-squash
```

### Q : Que se passe-t-il si le script plante ?
**R :** Le script s'arrête dès la première erreur (`set -e`). Vous pouvez simplement :
```bash
git checkout main
git reset --hard backup-before-squash
```

### Q : Combien de temps ça prend ?
**R :** 2-5 minutes pour tout le processus (création des 51 commits).

### Q : Est-ce que ça va casser Komodo ?
**R :** Non, mais vous devrez mettre à jour le repo sur le Raspberry Pi avec :
```bash
git fetch origin && git reset --hard origin/main
```

### Q : Pourquoi 51 commits et pas un nombre différent ?
**R :** Les commits ont été groupés de manière logique par fonctionnalité (ex: tous les commits Gluetun ensemble, tous les commits Traefik ensemble, etc.). 51 groupes = 51 commits finaux.

### Q : Je veux ajuster les groupes de commits
**R :** Éditez le fichier `git-squash-alternative.sh` et modifiez les sections "Groupe X". Chaque groupe a un commit de référence (hash) et un message.

### Q : Le script peut-il échouer ?
**R :** Le script fait des vérifications avant de commencer :
- Working directory propre
- Sur la branche main
- Repo Git valide

Si une vérification échoue, le script s'arrête et vous explique quoi faire.

---

## 🆘 En cas de problème

### Problème : "You have unstaged changes"
```bash
git stash
./git-squash-alternative.sh
git stash pop
```

### Problème : "not a git repository"
```bash
cd /Users/ls/docker  # Vérifiez que vous êtes dans le bon dossier
```

### Problème : Le script ne se lance pas
```bash
chmod +x git-squash-alternative.sh  # Rendez-le exécutable
```

### Problème : Je veux annuler tout
```bash
git checkout main
git reset --hard backup-before-squash
git branch -D main-squashed  # Si elle existe
```

---

## ✅ Checklist complète

- [ ] Je suis dans `/Users/ls/docker`
- [ ] Mon `git status` est clean (pas de changements non commités)
- [ ] J'ai lu les avertissements
- [ ] J'ai lancé `./git-squash-alternative.sh`
- [ ] Le script s'est terminé avec succès
- [ ] J'ai vérifié avec `git log --oneline` (~51 commits)
- [ ] J'ai fait `git push --force origin main`
- [ ] J'ai mis à jour le Raspberry Pi
- [ ] Komodo fonctionne toujours
- [ ] (Optionnel) J'ai supprimé `backup-before-squash`

---

## 📞 Support

Si vous rencontrez un problème non documenté ici :

1. **Annulez tout** : `git reset --hard backup-before-squash`
2. **Consultez** `git-rebase-plan.md` pour plus de détails
3. **Vérifiez** que votre working directory est propre

---

## 🎉 Résultat final

Après avoir suivi ce guide, votre historique Git sera :

- ✅ **Propre** : 51 commits logiques au lieu de 497
- ✅ **Lisible** : Chaque commit a un message clair (format conventional)
- ✅ **Identique** : Le code final est exactement le même
- ✅ **Professionnel** : L'historique raconte une vraie histoire du projet

**Félicitations !** 🎊

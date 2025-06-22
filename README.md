# Fight Club

## Structure du projet

```text
.
├── infrastructure/       # Réseaux Docker partagés
├── adguardhome/
├── autoheal/
├── bazarr/
├── beets/
├── deemix/
├── diun/
├── dozzle/
├── freshrss/
├── gluetun/
├── homarr/
├── infisical/
├── jellyfin/
├── jellyseerr/
├── jellystat/
├── komf/
├── komga/
├── mediamanager/
├── meilisearch/
├── notifiarr/
├── qbit_manage/
├── qdirstat/
├── qui/
├── radarr/
├── sonarr/
├── sops/
├── suwayomi/
├── traefik/
├── unpackerr/
├── uptime-kuma/
├── webhook/
└── ...
```

## Stack Technique

La stack actuelle est gérée grâce a **Komodo**.
Chaque fichier d'environnement est produit automatiquement a l'aide d'**Infisical**.

## Infrastructure

Le dossier `infrastructure/` contient la définition des reseaux Docker partagés :

- **proxy** (172.19.0.0/16) : Réseau pour Traefik et les services exposés
- **media_int** (172.20.0.0/16) : Réseau interne pour les applications *arr
- **vpn_net** (172.31.0.0/16) : Réseau pour Gluetun et les services VPN

### Déploiement avec Komodo

1. **Déployer la stack infrastructure en premier**

   Cette stack doit etre déployee avant toutes les autres car elle crée les reseaux partagés.

   ```bash
   # Dans Komodo, deployer la stack 'infrastructure' en premier
   ```

2. **Déployer les autres stacks**

   Une fois les reseaux créés, toutes les autres stacks peuvent etre déployées dans n'importe quel ordre.

### Déploiement manuel (sans Komodo)

```bash
# 1. Creer les reseaux
cd infrastructure
docker compose up -d
cd ..

# 2. Deployer les services
for dir in */; do
    if [ -f "$dir/docker-compose.yml" ] && [ "$dir" != "infrastructure/" ]; then
        echo "Deploying $dir..."
        (cd "$dir" && docker compose up -d)
    fi
done
```

### Migration depuis l'ancien système

Si vous utilisiez des reseaux `external: true` créés manuellement :

```bash
# 1. Arreter tous les services
docker compose down

# 2. Supprimer les anciens reseaux externes
docker network rm proxy media_int vpn_net

# 3. Deployer la stack infrastructure
cd infrastructure && docker compose up -d && cd ..

# 4. Redeployer tous les services
# ...
```

## Development

### Pre-commit hooks

```bash
# Installer les hooks
uv run pre-commit install

# Verifier tous les fichiers
uv run pre-commit run --all-files
```

### Scripts utilitaires

- `scripts/fix_compose_order.py` : Reorganise l'ordre des clés dans les fichiers compose
- `scripts/check_compose_order.py` : Verifie l'ordre des clés
- `scripts/update_networks.py` : Met a jour les references reseau
- `scripts/validate_compose.sh` : Valide la syntaxe des fichiers compose

### Ajouter un nouveau service

1. Creer un dossier `<service-name>/`
2. Ajouter un `docker-compose.yml`
3. Utiliser `extends` pour heriter de `common.yml`
4. Referencer les reseaux necessaires : `networks: [proxy]` ou `networks: [proxy, media_int]`
5. Ne pas definir la section `networks:` globale (elle est gérée par infrastructure)

Exemple :

```yaml
---
services:
  monservice:
    extends:
      file: ../common.yml
      service: common-config
    image: monimage:latest
    container_name: monservice
    networks: [proxy]
    # ...
```

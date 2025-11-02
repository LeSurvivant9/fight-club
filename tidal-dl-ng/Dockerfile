# 1. Image de base (Python 3.12 est requis par tidal-dl-ng)
FROM python:3.12-slim

# 2. Installation des dépendances système
# ffmpeg est nécessaire pour le traitement audio (extraction flac, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 3. Installation de l'application
# Nous installons la version CLI (ligne de commande).
RUN pip install --no-cache-dir --upgrade tidal-dl-ng

# 4. Configuration des volumes
# /config gardera votre token de connexion en mémoire
# /downloads sera le dossier où la musique est téléchargée
ENV XDG_CONFIG_HOME=/config
VOLUME /config
VOLUME /downloads

# 5. Définition du dossier de travail
WORKDIR /downloads

# 6. Commande pour garder le conteneur en vie
# Cela vous permet de vous y connecter avec 'docker exec'
CMD ["tail", "-f", "/dev/null"]
#!/bin/sh
set -e # Arrête le script si une commande échoue

# Chemin vers le fichier URL, tel que vu par le conteneur
URL_FILE="/config/urls.txt"

echo "--- Démarrage du script de téléchargement en boucle ---"

# Boucle infinie
while true; do
    # Vérifie si le fichier existe et n'est PAS vide
    if [ ! -s "$URL_FILE" ]; then
        echo "Le fichier urls.txt est vide. En attente (1h)..."
        sleep 3600
        continue # Redémarre la boucle
    fi

    # Lit la PREMIÈRE ligne du fichier
    URL=$(head -n 1 "$URL_FILE")

    echo "--- Traitement de l'URL : $URL ---"

    # Tente le téléchargement
    # Nous désactivons 'set -e' temporairement pour gérer l'échec
    set +e
    tidal-dl-ng dl "$URL"
    EXIT_CODE=$?
    set -e

    # Vérifie si le téléchargement a réussi
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Téléchargement réussi. Suppression de l'URL de la liste."
        # 'sed -i '1d'' supprime la première ligne du fichier
        sed -i '1d' "$URL_FILE"
    else
        echo "Échec du téléchargement (Code: $EXIT_CODE). L'URL sera ré-essayée plus tard."
        # Déplace la ligne échouée à la fin du fichier
        sed -i '1d' "$URL_FILE"
        echo "$URL" >> "$URL_FILE"
        echo "Erreur, pause de 5 minutes avant de continuer..."
        sleep 300
    fi

    echo "--- Tâche terminée. En attente de 5s... ---"
    sleep 5
done
#!/bin/bash
set -e

# Variable pour savoir si on a encrypté un fichier
ENCRYPTED_COUNT=0

for file in "$@"; do
  # Vérifie si le fichier est DÉJÀ crypté (contient 'sops:' ou 'sops_')
  if grep -qE "(^sops:|^sops_)" "$file"; then
    # Déjà crypté, on l'ignore
    echo "Fichier déjà crypté, ignoré : $file"
  else
    # Fichier non crypté, on l'encrypte
    echo "Nouveau fichier secret détecté, cryptage : $file"
    sops -e -i "$file"
    ENCRYPTED_COUNT=$((ENCRYPTED_COUNT + 1))
  fi
done

# Si on a crypté un fichier, on dit à git de le re-stager
if [ $ENCRYPTED_COUNT -gt 0 ]; then
  echo "Fichiers cryptés. N'oubliez pas de les 'git add' avant de commit !"
  exit 1
fi

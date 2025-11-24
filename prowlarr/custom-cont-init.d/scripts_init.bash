#!/bin/bash
GIST_ID="8bfded23ef23ec78f6678896f42a2b60"
DEFINITIONS_DIR="/config/Definitions/Custom"
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "=== Vérification YGG-API ==="

lastCommit=$(curl -s "https://api.github.com/gists/$GIST_ID/commits" | jq -r '.[0].committed_at')
echo "Dernier commit: $lastCommit"

files=$(curl -s "https://api.github.com/gists/$GIST_ID" | jq -r '.files | keys[] | select(endswith(".yml"))')

NEED_RESTART=false

for file in $files; do
    filepath="$DEFINITIONS_DIR/$file"
    filebase="${file%.yml}"
    variant=$(echo "$filebase" | sed 's/ygg-api-//' | sed 's/.*/\u&/')

    if [ -f "$filepath" ]; then
        lastWrite=$(date -r "$filepath" +"%Y-%m-%dT%H:%M:%SZ" -u)

        if [[ "$lastCommit" > "$lastWrite" ]]; then
            echo "$file - Mise à jour"
            wget -qO "$filepath.tmp" "https://gist.githubusercontent.com/Clemv95/$GIST_ID/raw/$file"
            sed -i "s/^id: yggapi$/id: $filebase/" "$filepath.tmp"
            sed -i "s/^name: YggAPI$/name: YggAPI $variant/" "$filepath.tmp"
            mv "$filepath.tmp" "$filepath"
            chown "$PUID:$PGID" "$filepath"
            chmod 644 "$filepath"
            NEED_RESTART=true
        else
            echo "$file - Déjà à jour"
        fi
    else
        echo "$file - Nouveau fichier"
        wget -qO "$filepath.tmp" "https://gist.githubusercontent.com/Clemv95/$GIST_ID/raw/$file"
        sed -i "s/^id: yggapi$/id: $filebase/" "$filepath.tmp"
        sed -i "s/^name: YggAPI$/name: YggAPI $variant/" "$filepath.tmp"
        mv "$filepath.tmp" "$filepath"
        chown "$PUID:$PGID" "$filepath"
        chmod 644 "$filepath"
        NEED_RESTART=true
    fi
done

if [ "$NEED_RESTART" = true ]; then
    docker restart prowlarr
    echo "Prowlarr redémarré"
fi
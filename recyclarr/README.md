# Recyclarr

Cette stack rend les profils Sonarr/Radarr declaratifs via `Recyclarr`.

## Variables attendues

- `PUID`
- `PGID`
- `TZ`
- `RADARR_API_KEY`
- `SONARR_API_KEY`
- `RECYCLARR_CRON_SCHEDULE` (optionnel, `@daily` par defaut)

## Profils geres

- Radarr: `FC Shared Movies`
- Sonarr: `FC Shared Shows`
- Sonarr: `FC Anime 1080p`

Le design part de zero et ne cherche pas a renommer ou recycler les anciens profils. `FC Shared Movies` et `FC Shared Shows` gerent chacun un fallback automatique `4K -> 1080p`, tandis que `FC Anime 1080p` reste dedie aux animes.

Les custom formats locaux sous `config/custom-formats/` completent TRaSH avec des regles specifiques au setup: garde-fous de taille, groups de confiance, blocage `HFR` / `AI-Upscale` / `Custom.IMAX`, et priorites audio/langue.

## Validation recommandee sur le serveur

Depuis `/etc/komodo/repos/fight-club/recyclarr`:

```bash
docker compose run --rm recyclarr sync radarr --preview
docker compose run --rm recyclarr sync sonarr --preview
docker compose run --rm recyclarr sync radarr
docker compose run --rm recyclarr sync sonarr
```

## Notes d'exploitation

- La sync TRaSH de Notifiarr doit rester desactivee pour eviter deux sources d'ecriture.
- Le conteneur doit pouvoir joindre `radarr` et `sonarr` sur `media_int`, et GitHub via `proxy` pour initialiser les providers officiels.
- Les donnees runtime jetables vivent dans `/opt/recyclarr/data` sur le Raspberry Pi.

## Suivi manuel hors Recyclarr

Recyclarr ne pilote pas `Prowlarr`, les `Delay Profiles`, ni le nettoyage des anciens profils via ce repo. Apres la sync initiale, il reste a appliquer a la main :

- `Prowlarr`: priorites `c411=1`, `torr9=1`, `Nyaa=1`, `TPB=25`
- `Prowlarr`: seeders mini `1` sur les trackers prives, `5` sur `Nyaa`, `25` sur `TPB`
- `Prowlarr`: `Nyaa` reserve aux usages anime, `TPB` en secours seulement
- `Radarr`: delay profile films `6-12h`
- `Sonarr`: delay profile series `1-3h`, anime `30-60min`
- reset complet des anciens quality profiles avant la bascule finale

## Migration big bang

Si tu veux basculer d'un coup sans te soucier de l'existant, fais la migration comme une coupure nette :

1. desactive toute autre sync de profils/CFs (`Notifiarr`, scripts maison, imports manuels repetes)
2. sauvegarde `/opt/radarr/config` et `/opt/sonarr/config` avant la bascule
3. deploie la stack `recyclarr` et verifie que le service est sur `media_int` et `proxy`
4. lance les previews
5. supprime les anciens quality profiles restants (`Temp`, anciens profils FR/anime)
6. lance le sync reel pour creer les nouveaux profils `FC ...`
7. reaffecte les bibliotheques :
   - `movies` => `FC Shared Movies`
   - `shows` standards => `FC Shared Shows`
   - anime => `FC Anime 1080p`
8. applique ensuite les reglages manuels `Prowlarr` et `Delay Profiles`
9. lance `RSS Sync`, `Search Missing` ou tes recherches manuelles selon ton workflow
10. seulement une fois la reassignment terminee, supprime les anciens profils qui ne sont plus references

L'avantage de cette approche est simple : les nouveaux profils ont des noms explicites, l'ancien monde reste visible pendant la transition, puis tu nettoies une fois la bascule validee.

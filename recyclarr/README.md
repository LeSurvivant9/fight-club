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

- Radarr: `FC Shared FR-MULTi.VF HD`
- Radarr: `FC Shared FR-MULTi.VF UHD`
- Radarr: `FC Personal FR-MULTi.VO HD`
- Radarr: `FC Personal FR-MULTi.VO UHD`
- Sonarr: `FC Shared FR-MULTi.VF HD`
- Sonarr: `FC Shared FR-MULTi.VF UHD`
- Sonarr: `FC Personal FR-MULTi.VO HD`
- Sonarr: `FC Personal FR-MULTi.VO UHD`
- Sonarr: `FC Anime 1080p`

Le design part de zero et ne cherche pas a renommer ou recycler les anciens profils. Les profils `Shared` sont en `MULTi.VF` pour privilegier un comportement familial, les profils `Personal` restent en `MULTi.VO` pour ton usage, et `FC Anime 1080p` reste dedie aux animes.

Des overrides legers privilegient `VFF` / `VF2` par rapport a `VFQ`, et les films 4K recoivent un bonus modere pour l'audio premium sans basculer vers une logique remux-first.

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
- Le conteneur doit pouvoir joindre `radarr` et `sonarr` sur le reseau `media_int`.
- Les donnees runtime jetables vivent dans `/opt/recyclarr/data` sur le Raspberry Pi.

## Migration big bang

Si tu veux basculer d'un coup sans te soucier de l'existant, fais la migration comme une coupure nette :

1. desactive toute autre sync de profils/CFs (`Notifiarr`, scripts maison, imports manuels repetes)
2. sauvegarde `/opt/radarr/config` et `/opt/sonarr/config` avant la bascule
3. deploie la stack `recyclarr` et lance les previews
4. lance le sync reel pour creer les nouveaux profils `FC ...`
5. dans Radarr et Sonarr, fais un `Bulk Edit` de toutes les bibliotheques :
   - bibliotheques partagees => profils `FC Shared FR-MULTi.VF ...`
   - bibliotheques perso => profils `FC Personal FR-MULTi.VO ...`
   - animes => `FC Anime 1080p`
6. lance ensuite les recherches automatiques ou manuelles qui vont avec ton workflow (`RSS Sync`, `Search Missing`, etc.)
7. seulement une fois la reassignment terminee, supprime les anciens profils qui ne sont plus references

L'avantage de cette approche est simple : les nouveaux profils ont des noms explicites, l'ancien monde reste visible pendant la transition, puis tu nettoies une fois la bascule validee.

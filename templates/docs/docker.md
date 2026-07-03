# Docker

<!-- TODO : compléter quand la conteneurisation est en place. -->

## Principe

Front **et** back conteneurisés ; orchestration par `docker-compose.yml` à la racine ;
interface unique via Make.

```bash
make docker-up      # build + démarrage
make logs           # logs agrégés
make docker-down    # arrêt
```

## Règles

- **Aucun secret dans les images** : variables sensibles via `.env` (gitignoré) —
  fournir un `.env.example` documenté.
- Données persistées via **volumes** (jamais dans le conteneur).
- Images de prod **multi-stage** (build → runtime minimal).

## Services

| Service | Image | Port | Notes |
|---------|-------|------|-------|
| _TODO_ | | | |

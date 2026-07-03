# CI/CD

## Principe

Deux familles de pipelines, alignées sur le [workflow Git](./git-workflow.md) :

| Déclencheur | Workflows | Objectif |
|-------------|-----------|----------|
| **PR → `dev`** | `ci-dev-lint`, `ci-dev-tests` | Checks **rapides** : lint (Biome + limite 300 lignes), tests unitaires et intégration. |
| **PR → `main`** | `ci-main-e2e`, `ci-main-system`, `ci-main-build` | Checks **complets** avant production : e2e navigateur, tests système, build. |

## Jobs

- **lint** : `make lint` — Biome sur tout le dépôt + `scripts/check-max-lines.sh`
  (échec si un fichier source dépasse **300 lignes**).
- **tests (dev)** : unitaires + intégration, front et back.
- **e2e (main)** : stack démarrée puis Cypress headless.
- **système (main)** : vrai serveur HTTP + client réel.
- **build (main)** : build de production (front et back), artefacts vérifiés.

## Règles

- Un check rouge **bloque la fusion** (branches protégées).
- Interdiction de modifier/affaiblir les workflows pour faire passer la CI
  (voir `CLAUDE.md`, règle d'intégrité).

<!-- TODO : ajouter le déploiement (registry Docker, environnements) quand il existera. -->

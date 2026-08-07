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

## Publication : la pipeline fait foi

Le hook `.claude/hooks/check-ci-before-publish.sh` (PreToolUse) vérifie l'état
**réel** de la pipeline pour le **commit courant** avant toute commande publiante :
`git push` vers `main`/`master`/`dev`/`prod`, push de tags, `gh pr merge` /
`glab mr merge`, `npm|pnpm|yarn|bun publish`, `gh|glab release create`.

| État de la pipeline sur le commit | Décision |
|---|---|
| tout vert | la commande passe |
| rouge (`failure`, `timed_out`, `cancelled`) | **refus** — on corrige le **code** |
| en cours (`queued`, `in_progress`, `running`) | **refus** — attendre (`gh pr checks --watch`, `glab ci status`) |
| aucun run pour ce commit, CLI absente, réseau KO | **confirmation humaine** |

Le push d'une branche `feature/*` ou `hotfix/*` passe toujours : c'est lui qui
déclenche la pipeline.

**Contournements refusés sans condition** : `--no-verify`, `[skip ci]` /
`[ci skip]`, `-o ci.skip`, `gh pr merge --admin`, `gh workflow disable`,
`gh run cancel`, `glab ci cancel`, et toute tentative de désarmer un garde-fou
depuis une commande. Sur les fichiers de workflow, `continue-on-error: true`,
`allow_failure: true` et un `|| true` sur une commande de test sont refusés ;
`if: false` et `when: never` demandent confirmation.

`REQUIRE_GREEN_CI=0` dans l'environnement de la session ({{OWNER}} uniquement)
désactive la seule interrogation réseau — jamais les anti-contournements.

## Règles

- Un check rouge **bloque la fusion** (branches protégées) **et la publication**.
- Interdiction de modifier/affaiblir les workflows pour faire passer la CI
  (voir `CLAUDE.md`, règle d'intégrité) — le hook ci-dessus l'applique.

<!-- TODO : ajouter le déploiement (registry Docker, environnements) quand il existera. -->

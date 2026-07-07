# {{PROJECT_NAME}}

{{PROJECT_DESC}}

**Stack** : TypeScript — {{FRAMEWORK}}.

<!-- TODO : 2-3 phrases sur ce que fait l'application, points clés. -->

## 🚀 Pour lancer l'application

### Prérequis

- **Node.js {{NODE_VERSION}}** (LTS, voir `.nvmrc`) et npm
<!-- >>only:docker -->
- **Docker** (pour le démarrage conteneurisé)
<!-- <<only -->
- **Make** (interface de commandes)

<!-- >>only:docker -->
### Démarrage rapide (Docker)

```bash
cp .env.example .env    # compléter les variables (jamais commité)
make docker-up          # stack conteneurisée (docker compose)
make logs               # logs des conteneurs
make docker-down        # arrêt
```
<!-- <<only -->

<!-- >>only:docker -->
### Démarrage local (hors Docker)
<!-- <<only -->
<!-- >>only:package -->
### Démarrage local
<!-- <<only -->

```bash
make install        # dépendances
make dev            # démarrage en mode développement
```

<!-- TODO : URLs locales (front, API), variables d'environnement requises (.env.example). -->

## 🧪 Tests & qualité

```bash
make lint           # Biome + limite 300 lignes/fichier
make test           # unitaires + intégration
make test-unit      # unitaires
make test-int       # intégration
<!-- >>only:e2e -->
make test-e2e       # e2e (navigateur)
<!-- <<only -->
<!-- >>only:system -->
make test-system    # système (vrai serveur HTTP)
<!-- <<only -->
make test-mutation  # mutation (Stryker)
```

La stratégie complète (niveaux, conventions d'emplacement et de nommage) est
décrite dans [`docs/testing.md`](./docs/testing.md).

## 📚 Documentation

| Document | Contenu |
|----------|---------|
| [`docs/architecture.md`](./docs/architecture.md) | Architecture applicative et choix techniques |
| [`docs/data-model.md`](./docs/data-model.md) | Modèle de données |
| [`docs/testing.md`](./docs/testing.md) | Stratégie de tests |
| [`docs/ci-cd.md`](./docs/ci-cd.md) | Pipelines CI/CD |
| [`docs/git-workflow.md`](./docs/git-workflow.md) | Workflow Git (main/dev, PR, protections) |
<!-- >>only:docker -->
| [`docs/docker.md`](./docs/docker.md) | Conteneurisation |
<!-- <<only -->
| [`docs/tooling.md`](./docs/tooling.md) | Outillage (Make, Biome, hooks Claude Code) |
| [`docs/model-routing.md`](./docs/model-routing.md) | Routage de modèles (subagents Claude Code) |
| [`docs/security.md`](./docs/security.md) | Sécurité |
| [`docs/accessibility.md`](./docs/accessibility.md) | Accessibilité |
| [`docs/design.md`](./docs/design.md) | Design & UI |
<!-- >>only:storybook -->
| [`docs/storybook.md`](./docs/storybook.md) | Storybook (catalogue de composants) |
<!-- <<only -->
| [`docs/rgpd.md`](./docs/rgpd.md) | RGPD |
| [`docs/ameliorations.md`](./docs/ameliorations.md) | Pistes d'amélioration |

## Workflow Git

Deux branches permanentes : `main` (production, protégée) et `dev` (intégration).
Toute fonctionnalité passe par `feature/<nom>` → PR vers `dev` → CI verte → merge.
Détails : [`docs/git-workflow.md`](./docs/git-workflow.md).

> Projet géré par {{OWNER}}.

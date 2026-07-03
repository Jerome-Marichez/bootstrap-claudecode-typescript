# {{PROJECT_NAME}}

{{PROJECT_DESC}}

**Stack** : TypeScript — {{FRAMEWORK}}.

<!-- TODO : 2-3 phrases sur ce que fait l'application, points clés. -->

## 🚀 Pour lancer l'application

### Prérequis

- **Node.js 24** (LTS) et npm
- **Docker** (pour le démarrage conteneurisé)
- **Make** (interface de commandes)

### Démarrage rapide (Docker)

```bash
make docker-up      # stack conteneurisée (docker compose)
make logs           # logs des conteneurs
make docker-down    # arrêt
```

### Démarrage local (hors Docker)

```bash
make install        # dépendances
make dev            # démarrage en mode développement
```

<!-- TODO : URLs locales (front, API), variables d'environnement requises (.env.example). -->

## 🧪 Tests & qualité

```bash
make lint           # Biome + limite 300 lignes/fichier
make test           # tous les niveaux
make test-unit      # unitaires
make test-int       # intégration
make test-e2e       # e2e (navigateur)
```

La stratégie complète (niveaux unitaire / intégration / e2e / système, conventions
d'emplacement et de nommage) est décrite dans [`docs/testing.md`](./docs/testing.md).

## 📚 Documentation

| Document | Contenu |
|----------|---------|
| [`docs/architecture.md`](./docs/architecture.md) | Architecture applicative et choix techniques |
| [`docs/data-model.md`](./docs/data-model.md) | Modèle de données |
| [`docs/testing.md`](./docs/testing.md) | Stratégie de tests |
| [`docs/ci-cd.md`](./docs/ci-cd.md) | Pipelines CI/CD |
| [`docs/git-workflow.md`](./docs/git-workflow.md) | Workflow Git (main/dev, PR, protections) |
| [`docs/docker.md`](./docs/docker.md) | Conteneurisation |
| [`docs/tooling.md`](./docs/tooling.md) | Outillage (Make, Biome, hooks Claude Code) |
| [`docs/security.md`](./docs/security.md) | Sécurité |
| [`docs/accessibility.md`](./docs/accessibility.md) | Accessibilité |
| [`docs/design.md`](./docs/design.md) | Design & UI |
| [`docs/storybook.md`](./docs/storybook.md) | Storybook (catalogue de composants) |
| [`docs/rgpd.md`](./docs/rgpd.md) | RGPD |
| [`docs/ameliorations.md`](./docs/ameliorations.md) | Pistes d'amélioration |

## Workflow Git

Deux branches permanentes : `main` (production, protégée) et `dev` (intégration).
Toute fonctionnalité passe par `feature/<nom>` → PR vers `dev` → CI verte → merge.
Détails : [`docs/git-workflow.md`](./docs/git-workflow.md).

> Projet géré par {{OWNER}}.

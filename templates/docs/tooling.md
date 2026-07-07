# Outillage

## Make — interface de commandes unique

Toutes les opérations passent par `make` (voir `Makefile`) : agnostique, documenté
(`make help`), identique en local et en CI.

## Lint — Biome + limite 300 lignes

- **Biome** (`biome.json` à la racine) : lint + format TypeScript/React.
- **`scripts/check-max-lines.sh`** : échoue si un fichier source (`.ts`, `.tsx`,
  `.js`, `.jsx`) dépasse **300 lignes**. Exécuté par `make lint`, par la CI et par
  un hook Claude Code. Remède : extraire (sous-composants, hooks, services) —
  jamais d'exclusion de fichier.

```bash
make lint
```

## Hooks Claude Code (`.claude/`)

| Hook | Événement | Rôle |
|------|-----------|------|
| `route-task.sh` | UserPromptSubmit | Classifie la demande (architecture / feature / mécanique) et recommande le subagent adapté (voir [`model-routing.md`](./model-routing.md)) ; plafonne les recommandations si le budget crédits est bas (`CREDITS_LIMIT_TOKENS`). |
| `check-test-location.sh` | PreToolUse (Write) | Bloque la création d'un fichier de test hors de la convention (`docs/testing.md`). |
| `check-new-dependency.sh` | PreToolUse (Bash/Write/Edit/MultiEdit) | Nouvelle dépendance : ≥ 3 contributeurs, OU éditeur de confiance (Meta, Google, Amazon, Microsoft, Vercel… extensible via `TRUSTED_ORGS_EXTRA`) avec ≥ 1000 étoiles ; SemVer obligatoire ; publication > 6 mois → confirmation manuelle. |
| `check-file-length.sh` | PostToolUse (Write/Edit) | Avertit dès qu'un fichier source dépasse 300 lignes. |
| `remind-docs.sh` | PostToolUse (Write/Edit) | Rappelle de mettre à jour README/docs après une modification de code (au plus une fois par quart d'heure). |
| `remind-tests.sh` | PostToolUse (Write/Edit) | Rappelle la politique de tests (unitaire systématique, intégration/e2e sur demande) — même throttle. |

## Subagents Claude Code (`.claude/agents/`)

Trois subagents pré-définis portent le routage de modèles (`opus-architect`,
`opus-dev`, `haiku-mechanic`) — critères, garde-fous et sources dans
[`model-routing.md`](./model-routing.md).

## Skills Claude Code (`.claude/skills/`)

Ajouter ici les procédures récurrentes du projet (build, déploiement, fixes connus) —
un dossier par skill avec un `SKILL.md` (voir l'exemple fourni).

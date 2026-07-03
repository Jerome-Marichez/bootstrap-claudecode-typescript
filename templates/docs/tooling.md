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
| `check-test-location.sh` | PreToolUse (Write) | Bloque la création d'un fichier de test hors de la convention (`docs/testing.md`). |
| `check-new-dependency.sh` | PreToolUse (Bash/Write/Edit) | Nouvelle dépendance : ≥ 3 contributeurs ET publication < 6 mois, OU éditeur de confiance (Meta, Google, Amazon, Microsoft, Vercel…) avec ≥ 1000 étoiles. |
| `check-file-length.sh` | PostToolUse (Write/Edit) | Avertit dès qu'un fichier source dépasse 300 lignes. |
| `remind-docs.sh` | PostToolUse (Write/Edit) | Rappelle de mettre à jour README/docs après une modification de code. |
| `remind-tests.sh` | PostToolUse (Write/Edit) | Rappelle la politique de tests (unitaire systématique, intégration/e2e sur demande). |
| `guard-model-usage.sh` | UserPromptSubmit | Budget crédits : > 50 % consommés et reset < 2 h → interdit Fable 5/Opus max effort ; < 50 % et reset < 1 h → message violet « Fable 5 utilisable à fond ». Nécessite `CREDITS_LIMIT_TOKENS` (tokens du bloc 5 h) dans l'environnement. |

## Skills Claude Code (`.claude/skills/`)

Ajouter ici les procédures récurrentes du projet (build, déploiement, fixes connus) —
un dossier par skill avec un `SKILL.md` (voir l'exemple fourni).

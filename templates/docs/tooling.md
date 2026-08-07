# Outillage

## Make — interface de commandes unique

Toutes les opérations passent par `make` (voir `Makefile`) : agnostique, documenté
(`make help`), identique en local et en CI.

## Lint — Biome + limite 300 lignes

- **Biome** (`biome.json` à la racine) : lint + format TypeScript/React.
  Règles notables : `noExplicitAny` et **`noConsole`** en `error`. Pas de
  `console.*` dans le code applicatif — passer par le **service de log** du projet
  (voir [`frontend-practices.md`](./frontend-practices.md)) ; l'`override` de
  `biome.json` lève la règle pour les fichiers de log, config et scripts.
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
| `require-test-first.sh` | PreToolUse (Write/Edit/MultiEdit) | Impose l'ordre : le test d'abord, écrit par {{OWNER}}. Refuse toute écriture d'un fichier de test par l'assistant (délégation par `TESTS_WRITABLE_BY_ASSISTANT=1`, qui exige alors un en-tête `Intention :`) et demande confirmation avant d'écrire un fichier source qu'aucun test unitaire/intégration/système ne couvre. Désarmement : `REQUIRE_TEST_FIRST=0`. |
| `check-test-doubles.sh` | PreToolUse (Write/Edit/MultiEdit) | Refuse toute doublure de module (`jest.mock`, `vi.mock`, `__mocks__`, `sinon.stub`, `mockResolvedValue`, `moduleNameMapper` vers un mock) : les vrais services tournent sur les **jeux de données** de `tests/fixtures/`. Les frontières (MSW, Supertest, `listen(0)`, base de test) et `jest.fn()`/`jest.spyOn` restent autorisées. Désarmement : `ALLOW_TEST_DOUBLES=1`. |
| `check-test-location.sh` | PreToolUse (Write) | Bloque la création d'un fichier de test hors de la convention (`docs/testing.md`) ; `tests/fixtures/` en est exclu. |
| `check-ci-before-publish.sh` | PreToolUse (Bash/Write/Edit/MultiEdit) | **La pipeline fait foi.** Refuse toute commande publiante (push vers `main`/`dev`, push de tags, `gh pr merge`, `npm publish`, `gh release create`) si la pipeline du commit courant est rouge **ou en cours** ; confirmation humaine si l'état est invérifiable. Refuse les contournements (`--no-verify`, `[skip ci]`, `--admin`, `gh run cancel`) et la neutralisation d'un job (`continue-on-error`, `allow_failure`, `\|\| true`). Désarmement de la seule vérification réseau : `REQUIRE_GREEN_CI=0`. |
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

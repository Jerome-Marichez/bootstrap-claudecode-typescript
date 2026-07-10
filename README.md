# bootstrap-claudecode-typescript

**Plugin Claude Code** d'initialisation rapide de projets **TypeScript / React**
(Next.js ou Vite) **immédiatement fonctionnels** : documentation (`README.md` +
`docs/`), `CLAUDE.md`, hooks, subagents (routage de modèles) et skills Claude Code,
`package.json`/`tsconfig` câblés (Jest, Zod, Biome), Docker (multi-stage + compose),
structure de tests avec un test d'exemple qui passe, lint (Biome + règle **max 300
lignes / fichier**) et workflows CI (GitHub Actions ou GitLab CI) qui exécutent de
vraies commandes — `make install && make lint && make test && make build` passent
dès la génération.

> ⚠️ **État de la CI** : les workflows **GitHub Actions** sont testés et
> fonctionnels. Le `.gitlab-ci.yml` généré est un équivalent **non vérifié sur
> une vraie instance GitLab** — en l'état il ne fonctionne pas tel quel selon
> le runner (image, config git du runner…) et demande une adaptation manuelle.

**Prérequis du générateur** : bash, `jq`, `make` ; `gh` (auteur auto) et `curl`
pour le hook dépendances ; Node ≥ 24 pour travailler dans le projet généré.

> ⚠️ Plugin avant tout **personnel** : il encode *mes* conventions et habitudes de
> travail pour m'aider à bootstrapper mes projets rapidement. Utilisable par
> d'autres, mais les choix (structure, hooks, règles) reflètent ma façon de faire.

## Installation (plugin)

Le repo est à la fois un **plugin** et sa **marketplace** :

```bash
# dans Claude Code
/plugin marketplace add /Users/nicolasb/Desktop/bootstrap-claudecode-typescript
/plugin install bootstrap-claudecode-typescript@bootstrap-claudecode-typescript
```

(Une fois poussé sur GitHub : `/plugin marketplace add <owner>/bootstrap-claudecode-typescript`.)

Puis, depuis n'importe quel dossier :

```
/bootstrap-project
```

Claude pose les questions — type de projet (`front-back`, `single`, `package`),
framework (Next.js/Vite), CI (GitHub/GitLab), setup des tests (Jest + Stryker,
Cypress, Postman), tests d'acceptation (UAT), Storybook, dossier cible — puis
exécute le générateur et personnalise les fichiers.

## Utilisation en CLI (sans plugin)

```bash
./scripts/bootstrap.sh \
  --name mon-projet \
  --desc "Description courte du projet" \
  --layout front-back \        # ou : single (Next.js seul) | package (librairie npm)
  --framework nextjs \         # ou : vite
  --ci github \                # ou : gitlab | none
  --target ~/Desktop/mon-projet
  # options : --no-storybook --no-tests-setup --acceptance --postman --no-git
```

L'auteur est **toujours le compte lié à la forge** : le générateur prend le compte
connecté à la CLI GitHub (`gh api user`), à défaut `git config user.name` ;
`--owner "Nom"` ne sert qu'à forcer explicitement une autre valeur.

## Ce qui est généré

| Élément | Contenu |
|---------|---------|
| `README.md` | Squelette standard : présentation, démarrage rapide (Make/Docker), liens docs — adapté au layout |
| `CLAUDE.md` | Règles projet : workflow Git 2 branches, micro-features (`/create-feat`), mise en prod (`/merge-prod`), politique de tests, politique doc, routage de modèles, intégrité CI, limite 300 lignes — adapté au layout |
| `docs/` | 14 docs standards : architecture, testing, ci-cd, git-workflow, docker, tooling, model-routing, security, accessibility, design, storybook, data-model, rgpd, ameliorations — adaptées au layout |
| `package.json` + `tsconfig.json` | **Câblés et fonctionnels** par layout/framework : Next.js ou Vite + React, Zod, Jest + ts-jest, Biome, Stryker, Cypress ; back node:http minimal (front-back) ; tsup + exports ESM/CJS (package) |
| Docker | `Dockerfile` multi-stage (`node:24-alpine`) par app + `docker-compose.yml` + `.env.example` — sauf layout package |
| `.claude/hooks/` | `route-task.sh` (routage de modèles + budget crédits), `check-test-location.sh`, `check-file-length.sh` (300 lignes), `check-new-dependency.sh`, `remind-docs.sh`, `remind-tests.sh` |
| `.claude/agents/` | `opus-architect` (opus, xhigh), `opus-dev` (opus, medium), `opus-frontend` (opus, medium, si UI), `haiku-mechanic` (haiku) — cibles du routage de modèles |
| `.claude/settings.json` | Câblage des hooks UserPromptSubmit / PreToolUse / PostToolUse |
| `.claude/skills/` | `/create-issue` (template d'issue commun obligatoire, sans emoji), `/create-feat` (issue → branche dev → worktree → subagent → PR), `/merge-prod` (PR dev→main, CI vérifiée, merge humain), exemple |
| Structure `src/` | `interfaces/` (entités `IXxx` + `types.ts`), `schemas/` (validation **Zod**), `services/` (métier), `utils/`, `components/`, `views/`, `hooks/` |
| `shared/` (front-back) | Interfaces d'entités et schémas Zod **partagés entre front et back** (`shared/interfaces/`, `shared/schemas/`) — jamais de duplication |
| Tests | `front/tests/{unitaire,integration,e2e}` + `back/tests/{unitaire,integration,systeme}` (front-back), `tests/{unitaire,integration,e2e,systeme}` (single) ou `tests/{unitaire,integration}` (package) — avec configs **Jest**, **Stryker** (mutation), **Cypress** (e2e), collection **Postman** (système API), un **test unitaire d'exemple qui passe** (chaîne Jest+ts-jest validée dès le bootstrap), et en option `tests/acceptance/` + UAT (disponibilité, sécurité, performance, robustesse) |
| Lint | `biome.json` + `scripts/check-max-lines.sh` (300 lignes) + `make lint` |
| CI | GitHub : `ci-dev-lint` (Biome + 300 lignes), `ci-dev-tests`, `ci-main-e2e`, `ci-main-system`, `ci-main-build`, `release-main` (tag `vX.Y.Z` + release SemVer automatiques à chaque push sur `main`) — ou GitLab : `.gitlab-ci.yml` équivalent (job `release` inclus), **non vérifié sur une vraie instance, adaptation manuelle à prévoir**. Les jobs exécutent les **vraies** cibles Make (aucun `echo TODO`) |
| `Makefile` | Interface unique aux **cibles réelles** : install, dev, build, lint, test-* (unit, int, e2e, system, mutation, acceptance), storybook, docker-* — adaptées au layout |
| `.nvmrc` | Version Node unique — point de vérité `NODE_VERSION` dans `bootstrap.sh`, propagé aux workflows GitHub (`node-version-file`), à l'image GitLab et aux Dockerfiles |
| Template d'issue | `.github/ISSUE_TEMPLATE/issue.md` ou `.gitlab/issue_templates/issue.md` — modèle **commun** (type bug/feature/documentation/autre, description, critères d'acceptation, impacts), imposé par le skill `/create-issue`, sans emoji |
| Git | `git init` + commit de bootstrap + branches `main` et `dev` |

## Benchmark — tokens et coût API mesurés

Benchmark empirique (juillet 2026) : pour chaque layout, un agent **Claude
Opus 4.8** a reçu la spécification complète de la structure et l'interdiction
d'utiliser le générateur — il a écrit chaque fichier lui-même via `Write`.
Un quatrième agent identique a exécuté le plugin (`bootstrap.sh`, layout
package). Les tokens sont l'**usage API réel** agrégé depuis les transcripts
(champ `usage` de chaque réponse), le coût est calculé au tarif Opus 4.8
(entrée 5 $/M, sortie 25 $/M, écriture cache 6,25 $/M, lecture cache 0,50 $/M).

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/benchmark-dark.svg">
  <img src="assets/benchmark-light.svg" alt="Tokens de sortie mesurés par layout : sans plugin 22 011 à 25 801 tokens (Opus 4.8 écrivant chaque fichier, 2,36 à 11,04 $ par run), avec plugin 1 007 tokens (0,41 $), soit ~95-96 % d'économie" width="760">
</picture>

| Run | Fichiers écrits | Requêtes API | Tokens sortie | Tokens entrée (+ cache) | Coût API total | Durée |
|---|---|---|---|---|---|---|
| Sans plugin — `front-back` | 62 | 74 | **23 059** | 2 916 308 | **11,04 $** | 6 min 31 s |
| Sans plugin — `single` | 52 | 57 | **25 801** | 2 026 995 | **2,36 $** | 5 min 58 s |
| Sans plugin — `package` | 43 | 54 | **22 011** | 1 746 445 | **4,12 $** | 5 min 00 s |
| **Avec plugin** — `package` | 43 | 9 | **1 007** | 154 768 | **0,41 $** | **20 s** |

Soit **~95-96 % de tokens de sortie en moins**, un coût divisé par **6 à 27**
selon le layout, et une exécution **15 à 20× plus rapide** — avec un résultat
déterministe (le bras manuel produit un nombre de fichiers variable et un
contenu différent à chaque run).

**Méthodologie et limites** : n=1 run par layout (la variance inter-run n'est
pas mesurée — l'écart de coût entre layouts vient surtout du comportement du
cache de prompt, visible sur `front-back` : 1,5 M de tokens d'écriture cache).
Le coût du bras plugin est quasi indépendant du layout (une commande Bash +
vérification). Les agents « sans plugin » recevaient la spec exacte des
fichiers attendus ; en conditions réelles, sans spec, le modèle dépenserait
davantage en exploration et produirait un résultat encore moins conforme.

## Hooks embarqués

| Hook | Événement | Rôle |
|------|-----------|------|
| `route-task.sh` | UserPromptSubmit | **Routage de modèles** : classifie la demande (architecture / frontend / développement / mécanique) et recommande le subagent adapté — voir section suivante. Absorbe aussi le **budget crédits** : usage lu via `ccusage` avec **cache 10 min** (`CREDITS_LIMIT_TOKENS` requis) ; > 50 % consommés et reset < 2 h → recommandation plafonnée à opus-dev (effort medium) ; < 50 % et reset < 1 h → message « marge disponible ». |
| `check-test-location.sh` | PreToolUse (Write) | Bloque la création d'un fichier de test (`*.spec.*`, `*.test.*`, `*.cy.ts` — ts/tsx/js/jsx) hors de la convention `docs/testing.md`. |
| `check-new-dependency.sh` | PreToolUse (Bash/Write/Edit/MultiEdit) | Nouvelle dépendance acceptée si **≥ 3 contributeurs ET publication < 6 mois**, OU **éditeur de confiance** (Meta, Google, Vercel, zod, jest… extensible via `TRUSTED_ORGS_EXTRA`) avec **≥ 1000 étoiles** ; version **SemVer** obligatoire (refus si non conforme ou indisponible). Publication > 6 mois hors éditeur de confiance → **confirmation manuelle** (paquet mature vs abandonné), plus de refus sec. |
| `check-file-length.sh` | PostToolUse (Write/Edit) | Alerte dès qu'un fichier source dépasse 300 lignes. |
| `remind-docs.sh` | PostToolUse (Write/Edit) | Rappelle de mettre à jour README/docs après une modification de code — throttlé (1 rappel / 15 min). |
| `remind-tests.sh` | PostToolUse (Write/Edit) | Rappelle la politique de tests (unitaire systématique ; intégration/e2e proposés) — même throttle. |

## Routage de modèles (subagents)

Chaque projet généré embarque un routage **sans perte de précision** (doc complète :
`templates/docs/model-routing.md`) : le hook `route-task.sh` classifie chaque prompt
(heuristique FR/EN instantanée, zéro appel réseau) et recommande un subagent de
`.claude/agents/` — le modèle **et** l'effort sont portés par leur frontmatter :

| Subagent | Modèle / effort | Tâches |
|----------|-----------------|--------|
| `opus-architect` | opus / xhigh | architecture, conception, migrations, sécurité, auth, paiement, concurrence, debugging profond |
| `opus-dev` | opus / medium | features, refactoring, bugfix non trivial, tests — **et toute la zone grise** |
| `opus-frontend` | opus / medium | composants React, vues, styles, responsive, a11y, Storybook — installé seulement si le projet a une UI (skippé en layout package sans Storybook), repli sur `opus-dev` sinon |
| `haiku-mechanic` | haiku | doc, renommages, formatage, commits, recherches |

Garde-fous : **défaut vers le haut** (zone grise → opus-dev (medium), jamais haiku) ; **escalade**
(`ESCALATE: <raison>` → re-délégation un cran au-dessus) ; recommandation
**outrepassable** par le modèle principal ; override utilisateur par préfixe `!!` ;
**fail-open** (toute erreur → aucune injection) ; journal JSONL `.claude/route-task.log`
pour ne descendre un type de tâche que mesure à l'appui. Conception appuyée sur
RouteLLM (seuil biaisé vers le modèle fort), les cascades LLM (routage + escalade)
et le frontmatter natif `model`/`effort` des subagents Claude Code.

## Niveaux de tests (convention)

| Niveau | Côté | Emplacement | Nommage |
|--------|------|-------------|---------|
| unitaire | front | `front/tests/unitaire/` | `*.spec.ts(x)` |
| intégration | front | `front/tests/integration/` | `*.integration.spec.ts(x)` |
| e2e (navigateur) | front | `front/tests/e2e/` | `*.cy.ts` |
| unitaire | back | `back/tests/unitaire/` | `*.test.ts` |
| intégration | back | `back/tests/integration/` | `*.test.ts` |
| système (vrai serveur HTTP) | back | `back/tests/systeme/` | `*.test.ts` |

## Règle des 300 lignes

Aucun fichier source (`.ts`, `.tsx`, `.js`, `.jsx`) ne dépasse **300 lignes** :

- **En local / Claude Code** : hook `check-file-length.sh` (rappel immédiat après Write/Edit) ;
- **En CI** : le job lint (`ci-dev-lint` / job `lint` GitLab) exécute
  `scripts/check-max-lines.sh` et **échoue** en cas de dépassement ;
- **`make lint`** : Biome + vérification des 300 lignes.

## Cycle de vie d'une fonctionnalité

Penser **micro-features** (plan mode privilégié pour le découpage/l'orchestration) ;
pour chaque micro-feature, `/create-feat` impose : **issue** → **branche `feature/<nom>`
dérivée de `dev`** → **worktree dédié** → **subagent dédié** → **PR vers `dev`**.
La mise en production passe par `/merge-prod` (merge humain uniquement).

## Conventions de code

- **`src/interfaces/`** : toutes les interfaces d'entités, préfixées `I` (`IProduct`) ;
  `src/interfaces/types.ts` pour les alias de types purs uniquement.
- **Validation des entrées — Zod (obligatoire)** : toute entrée externe (body/query
  d'API, formulaire, webhook, env) est validée par un schéma Zod de `schemas/`
  (`product.schema.ts`) ; types dérivés par `z.infer`, jamais de cast direct.
  En layout front-back, les schémas communs vivent dans `shared/schemas/`.
- **Découpage par domaine métier** : quand l'app
  grandit, le code front se regroupe par domaine sous `src/@<domaine>/` (`@core`,
  `@vitrine`, `@shared`…), chaque domaine portant ses `components/`, `hooks/`,
  `services/`, `utils/`, `interfaces/`.
- **Composant = un dossier** : `components/Button/index.tsx` + styles/assets
  colocalisés (`button.module.css`) ; composants purs par défaut, les non-purs
  (store, réseau, auth) isolés dans `_notPure/`.
- **`views/` vs `pages/`** : `pages/` (ou `app/`) ne fait que le routage ; les
  sections d'écran composées vivent dans `src/views/<domaine>/`.
- **Nommage des fichiers** : PascalCase pour les composants et vues (`Button.tsx`,
  `HomeView.tsx`) ; minuscules pour tout le reste (services, hooks, utilitaires).
- **Nommage des symboles** : PascalCase pour les **interfaces** (`IProduct`), les
  **composants `.tsx`** et les **classes métier** de `services/` (`CartService`) ;
  camelCase pour tout le reste (fonctions, variables, hooks `useCart`).
- **`src/services/`** : logique **métier** (règles de gestion, appels API) — les hooks
  React ne portent que la logique de **rendu**. **`src/utils/`** : utilitaires purs
  transverses.
- **Semantic Versioning** : version du projet et releases taguées `vX.Y.Z` ; exigé
  aussi des dépendances (hook `check-new-dependency.sh`).
- **Micro-features** : plan mode privilégié pour le découpage/l'orchestration ; le
  processus `/create-feat` (issue → branche → worktree → subagent) s'applique dans
  tous les cas.

## Personnaliser

Les templates vivent dans `templates/`. Tokens substitués : `{{PROJECT_NAME}}`,
`{{PROJECT_DESC}}`, `{{OWNER}}`, `{{FRAMEWORK}}`, `{{NODE_VERSION}}`,
`{{BIOME_VERSION}}` (points de vérité uniques en tête de `bootstrap.sh`).

Les templates portent aussi des **blocs conditionnels** : une ligne contenant
`>>only:tag1,tag2` ouvre un bloc conservé seulement si l'un des tags est actif
(`front-back`/`single`/`package`, `nextjs`/`vite`, `docker`, `storybook`, `e2e`,
`system`, `postman`, `acceptance`, `tests-setup`, `ci-github`/`ci-gitlab`) ; une
ligne contenant `<<only` le ferme (pas d'imbrication). Modifier un template ici
met à jour tous les futurs projets.

## Benchmark du routage de modèles

`./scripts/benchmark-routing.sh` mesure l'apport du routage sur une charge de
travail fixe (`scripts/benchmark-prompts.txt`, ou `benchmark-prompts-realworld.txt`
pour un codebase réel type RealWorld via `--install-cmd`/`--lint-cmd`/`--test-cmd`) :
deux bras (`routing` = hooks actifs vs `no-routing` = tout sur Opus via `!!`),
chaque prompt en session `claude -p` headless, usage API réel lu dans le JSON de
sortie, et garde-fou qualité après chaque bras (lint + tests unitaires — une
économie qui casse les tests ne vaut rien). Nécessite `claude`, `jq`, `rsync`,
`make`, `npm` ; coût : appels API réels.

## Développement du plugin

`./scripts/smoke-test.sh` génère quatre variantes (front-back Next.js, single Vite
avec git, package GitLab sans Storybook, package `--postman`) dans un dossier
temporaire et vérifie les invariants : structure, substitution des tokens et des
blocs conditionnels, filtrage CI par layout, **aucune cible Make en TODO**, Docker,
framework effectif, comportement de chaque hook (dont le routage de modèles :
up/down/zone grise/override/fail-open et le throttle des rappels), git init, et —
si le registre npm est joignable — la **résolution réelle des `package.json`**
générés. La CI du repo (`.github/workflows/ci.yml`) l'exécute à chaque push/PR sur
une matrice **ubuntu + macos** (les hooks ont des branches BSD `date -j`).

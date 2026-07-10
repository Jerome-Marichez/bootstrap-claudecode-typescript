# {{PROJECT_NAME}}

## Présentation

{{PROJECT_DESC}}

<!-- TODO : compléter — périmètre fonctionnel, contraintes techniques, choix retenus. -->

**Stack** : TypeScript — {{FRAMEWORK}} (front) ; Node.js/TypeScript (back le cas
échéant) ; **Zod** pour la validation des entrées.

> Projet géré par {{OWNER}}.

## Méthode de travail (workflow Git)

Le projet suit **toujours** un modèle à deux branches permanentes :

| Branche | Rôle |
|---------|------|
| `main`  | Branche de **production** — code stable, déployable, jamais cassé. |
| `dev`   | Branche d'**intégration** — développement courant, base des nouvelles fonctionnalités. |

### Règles

1. **Jamais de commit direct sur `main`.** `main` ne reçoit que des fusions depuis `dev` (ou des hotfix validés).
2. **Jamais de commit direct sur `dev`.** `dev` ne reçoit que des fusions depuis des branches de fonctionnalité (`feature/<nom>`).
3. **Toute nouvelle fonctionnalité suit le processus `/create-feat`** (skill **obligatoire**) : penser
   **micro-features** (petites unités livrables indépendamment ; plan mode privilégié
   pour l'orchestration/le découpage) puis, pour chaque micro-feature : **issue** →
   **branche `feature/<nom>` dérivée de `dev`** → **worktree dédié** → **subagent dédié**
   qui implémente dans ce worktree et ouvre la PR vers `dev`. Ce processus s'applique
   **aussi hors plan mode**, sans exception.
4. **Toute issue passe par `/create-issue`** (skill **obligatoire**), quel que soit
   son type (`bug`, `feature`, `documentation`, `autre`) : le **template d'issue
   commun** du dépôt (`.github/ISSUE_TEMPLATE/issue.md` ou
   `.gitlab/issue_templates/issue.md`) est rempli intégralement, titre au format
   `<type>: <résumé court>`, **jamais d'emoji** — pas d'issue en texte libre.
5. **Fusion d'une PR — la nuance `dev` vs `main`.**
   - **Vers `dev`** : dès que **tous les checks CI sont au vert**, la fusion est **autorisée en auto-merge** — l'assistant **peut fusionner lui-même** la PR.
   - **Vers `main`** (mise en production) : passe **obligatoirement** par le skill `/merge-prod` — PR ouverte et remplie par l'assistant après vérification de la CI de `dev`, mais **l'assistant n'a PAS le droit de la fusionner** — seule une **validation humaine** ({{OWNER}}) peut merger dans `main`.
6. **Hotfix** : `hotfix/<nom>` depuis `main`, fusionné dans `main` **et** `dev`.
7. **`main` est une branche protégée** : push direct interdit, PR obligatoire, checks CI au vert, revue approuvée. Détails : [`docs/git-workflow.md`](./docs/git-workflow.md).
8. **Intégrité des contrôles — aucun truquage.** L'assistant ne doit **jamais** modifier, désactiver, supprimer, ignorer (`skip`/`xfail`) ou affaiblir un **test**, une **assertion**, ni un **fichier de configuration CI/CD** (workflows, seuils de couverture, linters, limite de lignes…) dans le but de faire passer artificiellement la CI ou de masquer une régression. Les checks passent au vert **par une correction réelle du code**. Une évolution légitime d'un test reste possible, mais doit être **justifiée et documentée** dans la PR.
9. **Pas d'auto-modification des règles.** L'assistant ne modifie **jamais** ce `CLAUDE.md`, un skill, un hook ou toute règle du projet **pour contourner** les consignes. Toute évolution de ces règles se fait à la demande explicite de {{OWNER}}.
10. **CI en échec — corriger puis escalader.** L'assistant retente 2 à 3 fois en corrigeant réellement, puis **signale à {{OWNER}}** avec un diagnostic clair si le blocage persiste.

## Politique de tests

Référence complète : [`docs/testing.md`](./docs/testing.md). Convention d'emplacement
**imposée** (un hook bloque toute création hors convention) :

<!-- >>only:front-back -->
| Niveau | Côté | Emplacement | Nommage | Outil |
|--------|------|-------------|---------|-------|
| unitaire | front | `front/tests/unitaire/` | `*.spec.ts(x)` | Jest + React Testing Library |
| intégration | front | `front/tests/integration/` | `*.integration.spec.ts(x)` | Jest + RTL (vraie frontière HTTP pilotée par fixtures) |
| e2e | front | `front/tests/e2e/` | `*.cy.ts` | Cypress |
| unitaire | back | `back/tests/unitaire/` | `*.test.ts` | Jest |
| intégration | back | `back/tests/integration/` | `*.test.ts` | Jest + Supertest + base de test dédiée |
| système | back | `back/tests/systeme/` | `*.test.ts` | Jest + vrai serveur HTTP (`listen(0)`) + `fetch` ; collection **Postman** rejouable |
<!-- <<only -->
<!-- >>only:single -->
| Niveau | Emplacement | Nommage | Outil |
|--------|-------------|---------|-------|
| unitaire | `tests/unitaire/` | `*.spec.ts(x)` | Jest + React Testing Library |
| intégration | `tests/integration/` | `*.integration.spec.ts(x)` | Jest + RTL (vraie frontière HTTP pilotée par fixtures) |
| e2e | `tests/e2e/` | `*.cy.ts` | Cypress |
| système | `tests/systeme/` | `*.test.ts` | Jest + vrai serveur HTTP (`listen(0)`) + `fetch` ; collection **Postman** rejouable |
<!-- <<only -->
<!-- >>only:package -->
| Niveau | Emplacement | Nommage | Outil |
|--------|-------------|---------|-------|
| unitaire | `tests/unitaire/` | `*.test.ts` | Jest |
| intégration | `tests/integration/` | `*.test.ts` | Jest |
<!-- <<only -->
<!-- >>only:postman -->
| système (API) | `tests/systeme/` | `*.test.ts` | Jest ; collection **Postman** rejouable |
<!-- <<only -->
<!-- >>only:acceptance -->

**Acceptation / UAT** : `tests/acceptance/` (+ `uat/{disponibilite,securite,performance,robustesse}/`),
nommage `*.test.js|ts`, runner Node natif (`make test-acceptance`).
<!-- <<only -->

La **qualité** des tests unitaires/intégration est mesurée par **Stryker**
(mutation testing, `make test-mutation`) — ne jamais abaisser ses seuils.

Règles :

- **Unitaire = systématique** : chaque composant / logique créé(e) ou modifié(e) reçoit
  ses tests unitaires **sans demander**.
- **Intégration / e2e** : vérifier d'abord si un test pertinent existe ; sinon, si le
  composant le justifie (frontière API, accès base, auth ; parcours utilisateur critique
  pour e2e), **proposer** sa création à {{OWNER}} avant de le créer.
- **Pas de mocks des données métier** — utiliser des **fixtures** ; seules les
  frontières (HTTP, base de test) sont pilotées.
- Les tests **conditionnent la fusion** vers `dev`.

## Versionnage — Semantic Versioning

Le projet respecte **toujours** la convention **SemVer** (`MAJEUR.MINEUR.CORRECTIF`) :
version dans `{{VERSION_FILE}}` (point de vérité), releases taguées `vX.Y.Z`, incrément
selon la nature du changement (rupture → majeur, fonctionnalité → mineur,
correctif → patch). La release est **automatique** : à chaque push sur `main`, la CI
lit la version de `{{VERSION_FILE}}` et crée le tag `vX.Y.Z` + la release s'ils
n'existent pas encore. **Toute modification fusionnée sur `main` DOIT donc bumper la
version dans le même commit/PR**, sinon aucune release n'est publiée. Les
**dépendances** sont soumises à la même exigence par le hook `check-new-dependency.sh` :
un paquet dont la version ne respecte pas SemVer (ou dont l'information est
indisponible) est **refusé**.

## Qualité du code

- **Lint** : Biome (`make lint`) — la CI échoue si le lint échoue.
- **Limite de taille** : **aucun fichier source ne dépasse 300 lignes**
  (`scripts/check-max-lines.sh`, vérifié par hook local et par la CI).
  Si un fichier approche la limite : **extraire** (sous-composants, hooks, services),
  ne jamais contourner le contrôle.
- **TypeScript strict** : pas de `any` non justifié.
- **Nommage des fichiers** : **Majuscule (PascalCase)** uniquement pour les
  **composants React** (`Button.tsx`, `ProductCard.tsx`) et les **vues/pages** le cas
  échéant (`HomeView.tsx`) ; **tout le reste en minuscules** (`cart.service.ts`,
  `use-cart.ts`, `product.repository.ts`, `types.ts`).
- **Nommage des symboles** : **PascalCase** pour les **interfaces** (`IProduct`), les
  **composants `.tsx`** (`ProductCard`) et les **classes du dossier métier
  `services/`** (`CartService`) ; **camelCase** pour tout le reste (fonctions,
  variables, hooks `useCart`, instances).
<!-- >>only:front-back,single -->
- **Séparation métier / rendu (front)** : le front a **toujours** un dossier
  `services/` qui porte la **logique métier** (classes/fonctions pures, appels API,
  règles de gestion) ; les **hooks React** (`use-*.ts`) ne gèrent que la **logique de
  rendu** (état d'UI, abonnements, orchestration des services pour les composants) —
  jamais de règle métier dans un hook ou un composant.
<!-- <<only -->
- **`utils/`** : un dossier `src/utils/` regroupe **toujours**
  les **utilitaires** transverses (formatage, helpers purs, sans état ni métier).
- **Interfaces et types** : toutes les **interfaces d'entités** vivent dans le dossier
  `src/interfaces/` (un fichier par entité) et leur nom **commence toujours par `I`**
  (`IProduct`, `IUser`…). Les **alias de types purs** (unions, utilitaires) vont dans
  `src/interfaces/types.ts` — uniquement des `type`, jamais d'interface.
<!-- >>only:front-back -->
- **`shared/`** : les interfaces d'entités et schémas Zod
  **partagés entre le front et le back** vivent dans `shared/` à la racine
  (`shared/interfaces/`, `shared/schemas/`) — **jamais de duplication** d'une même
  entité côté front et côté back.
<!-- <<only -->
- **Validation des entrées — Zod (obligatoire)** : toute entrée externe (body/query
  d'API, formulaire, webhook, variables d'environnement) est validée par un schéma
  **Zod** avant usage. Les schémas vivent dans `schemas/` (un fichier par entité,
  `product.schema.ts` ; dans `shared/schemas/` si partagé front-back) et les types
  d'entrée sont **dérivés du schéma** (`z.infer`), jamais l'inverse. Aucun cast
  direct (`as`) d'une donnée externe.
<!-- >>only:front-back,single -->
- **Composant = un dossier** : chaque composant React vit dans son dossier PascalCase
  avec un `index.tsx` et ses styles/assets **colocalisés**
  (`components/Button/index.tsx` + `button.module.css`). Les composants sont **purs**
  par défaut ; ceux qui portent des effets (store, réseau, auth…) sont isolés dans un
  sous-dossier **`_notPure/`**.
- **`views/` vs `pages/`** : `pages/` (ou `app/`) ne fait **que le routage** ; les
  sections d'écran composées vivent dans `src/views/<domaine>/` et assemblent les
  composants.
- **Découpage par domaine** : quand l'app grandit, regrouper le code front par domaine
  métier sous `src/@<domaine>/` (ex. `@core` pour le socle applicatif, `@vitrine` pour
  le site public, `@shared` pour le transverse), chaque domaine portant ses propres
  `components/`, `hooks/`, `services/`, `utils/`, `interfaces/`.
<!-- <<only -->

## Politique de documentation

- Toute modification de code **impactante** met à jour le `README.md` et la doc `docs/`
  concernée (architecture, data-model, testing, ci-cd, docker, tooling…).
- Une nouvelle catégorie `docs/` créée doit être **liée** dans le `README.md` **et** ce `CLAUDE.md`.
- Docs disponibles : [architecture](./docs/architecture.md), [data-model](./docs/data-model.md),
  [testing](./docs/testing.md), [ci-cd](./docs/ci-cd.md), [git-workflow](./docs/git-workflow.md),
  [tooling](./docs/tooling.md), [model-routing](./docs/model-routing.md),
  [security](./docs/security.md),
  [accessibility](./docs/accessibility.md), [design](./docs/design.md),
  [frontend-practices](./docs/frontend-practices.md),
<!-- >>only:docker -->
  [docker](./docs/docker.md),
<!-- <<only -->
<!-- >>only:storybook -->
  [storybook](./docs/storybook.md),
<!-- <<only -->
  [rgpd](./docs/rgpd.md), [ameliorations](./docs/ameliorations.md).

## Skills projet (`.claude/skills/`)

Trois skills **obligatoires** encadrent le cycle de vie :

| Skill | Usage |
|-------|-------|
| `/create-issue` | **Obligatoire** pour créer toute issue (`bug`, `feature`, `documentation`, `autre`) : template d'issue commun rempli intégralement, titre `<type>: <résumé>`, jamais d'emoji. |
| `/create-feat` | **Obligatoire** pour démarrer toute fonctionnalité : issue (via `/create-issue`) → branche depuis `dev` → worktree → subagent dédié → PR vers `dev`. |
| `/merge-prod` | **Obligatoire** pour toute mise en production : vérifier la CI de `dev`, ouvrir la PR `dev` → `main`, surveiller les checks — **sans jamais merger** (validation humaine). |

Ajouter ici les procédures récurrentes du projet (build, déploiement, fixes connus).

## Routage de modèles (subagents `.claude/agents/`)

Le hook `route-task.sh` (UserPromptSubmit) classifie chaque demande et **recommande**
un subagent adapté — voir [`docs/model-routing.md`](./docs/model-routing.md) :

| Subagent | Modèle / effort | Tâches |
|----------|-----------------|--------|
| `opus-architect` | Opus, effort xhigh | architecture, conception, migrations, sécurité, debugging profond |
| `opus-dev` | Opus, effort medium | features, refactoring, bugfix non trivial, tests |
<!-- >>only:front-back,single,storybook -->
| `opus-frontend` | Opus, effort medium | composants React, vues, styles, responsive, a11y, Storybook (projets avec UI) |
<!-- <<only -->
| `haiku-mechanic` | Haiku | doc, renommages, formatage, git, recherches simples |

Règles : **en cas de doute, router vers le haut** (jamais de perte de précision pour
économiser) ; un subagent qui découvre que la tâche le dépasse répond `ESCALATE: <raison>`
et le travail est re-délégué un cran au-dessus ; la recommandation du hook peut être
outrepassée si le contexte de session l'exige.

## Commandes

Interface unique : **Make** (voir `Makefile`).

```bash
make install        # dépendances
make dev            # démarrage local
make lint           # Biome + limite 300 lignes
make test           # tous les niveaux de tests
<!-- >>only:docker -->
make docker-up      # stack conteneurisée
<!-- <<only -->
```

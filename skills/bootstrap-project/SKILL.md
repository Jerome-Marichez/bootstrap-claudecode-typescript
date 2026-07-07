---
name: bootstrap-project
description: Initialise un nouveau projet TypeScript/React avec la structure standard (README + docs/, CLAUDE.md, hooks & skills Claude Code, tests unitaire/integration/e2e/systeme, lint Biome + 300 lignes, CI GitHub ou GitLab). Pose les choix via AskUserQuestion puis exécute le générateur. À utiliser pour démarrer tout nouveau projet.
---

# Bootstrap d'un nouveau projet (`/bootstrap-project`)

Tu vas initialiser un projet avec la structure standard de l'utilisateur. Le gros du
travail est fait par le générateur `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh` —
ton rôle : recueillir les choix, l'exécuter, puis **personnaliser** le résultat.

## 1. Recueillir les choix (AskUserQuestion)

Procède en **deux temps** : le layout conditionne les questions suivantes, donc ne
pose jamais tout d'un coup.

**Appel 1 — toujours :**

1. **Nom du projet** (kebab-case) et **description courte** — si non fournis dans la
   demande initiale.
2. **Type de projet (layout)** : `front-back` (deux apps : front React + back API
   Node/TS), `single` (une seule app — typiquement Next.js avec ses API routes) ou
   `package` (librairie npm TypeScript, sans e2e/système).

**Appel 2 — adapté au layout choisi :**

Pour `front-back` ou `single` :

3. **Framework front** : `Next.js` (recommandé — habitude de l'utilisateur) ou
   `Vite + React`.
4. **CI** : `GitHub Actions` (workflows ci-dev-lint/tests + ci-main-e2e/system/build)
   ou `GitLab CI` (.gitlab-ci.yml équivalent) ou `aucune`.
5. **Setup des tests dès le départ ?** oui (recommandé) → configs **Jest** + **Stryker**
   (unitaire/intégration), **Cypress** (e2e), collection **Postman** (système API) /
   non → structure de dossiers seulement (`--no-tests-setup`).
6. **Tests non-fonctionnels / d'acceptation ?** (`--acceptance`) : ajoute
   `tests/acceptance/` + `uat/{disponibilite,securite,performance,robustesse}` —
   à proposer si l'app a des exigences de dispo/sécu/perf.
7. **Storybook** : oui (recommandé si UI riche) / non.
8. **Dossier cible** : par défaut `~/Desktop/<nom-du-projet>`.

Pour `package` (librairie npm, agnostique de tout framework — **ne propose PAS**
framework front ni e2e/Cypress ; les questions doivent le refléter) :

3. **CI** : `GitHub Actions` / `GitLab CI` / `aucune` — jobs lint + tests
   unitaires/intégration + build (pas de e2e ; system seulement si Postman ci-dessous).
4. **Setup des tests dès le départ ?** oui (recommandé) → configs **Jest** +
   **Stryker** (unitaire/intégration) / non (`--no-tests-setup`).
5. **La librairie expose-t-elle une API ?** oui → tests système **Postman**
   (`--postman` : tests/systeme + collection + job CI system) / non.
6. **Tests non-fonctionnels / d'acceptation ?** (`--acceptance`) : ajoute
   `tests/acceptance/` + `uat/{disponibilite,securite,performance,robustesse}` —
   à proposer si la lib a des exigences de perf/sécu/robustesse.
7. **Storybook** : oui (recommandé si librairie de composants UI) / non
   (recommandé pour une lib purement logique).
8. **Dossier cible** : par défaut `~/Desktop/<nom-du-projet>`.

Pour un `package`, ne passe pas `--framework` (ignoré, la lib est agnostique).

## 2. Exécuter le générateur

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh \
  --name <nom> --desc "<description>" \
  --layout <front-back|single|package> [--framework <nextjs|vite>] \
  --ci <github|gitlab|none> [--no-storybook] [--no-tests-setup] [--acceptance] [--postman] \
  --target <dossier>
```

**Ne pas passer `--owner`** : l'auteur est toujours le compte lié à la forge —
le générateur prend le compte connecté à la CLI GitHub (`gh api user`), à défaut
`git config user.name`. `--owner` ne sert qu'à forcer explicitement autre chose.

Le générateur crée un projet **immédiatement fonctionnel** : README.md, CLAUDE.md,
docs/ (14 docs, adaptées au layout), .claude/ (hooks : routage de modèles
`route-task.sh`, emplacement des tests, 300 lignes, dépendances, rappels doc/tests ;
settings.json ; subagents `opus-architect`/`opus-dev`/`haiku-mechanic` ; skills
`/create-issue`, `/create-feat`, `/merge-prod`), **package.json + tsconfig.json
câblés** (Zod, Jest, Biome ; Next.js ou Vite réellement installés selon le
framework ; serveur back node:http minimal en front-back ; tsup en package),
structure de tests + configs Jest/Stryker/Cypress/Postman + test d'exemple qui
passe, `src/interfaces/` (entités `IXxx` + `types.ts`), `src/schemas/` (validation
**Zod**), `src/{components,views,hooks,services,utils}`, `shared/{interfaces,schemas}`
(front-back), **Docker** (Dockerfile multi-stage + docker-compose.yml + .env.example,
sauf package), Makefile aux cibles réelles (install/dev/build/lint/test-*),
biome.json, `.nvmrc`, scripts/check-max-lines.sh, workflows CI, template d'issue
commun (`.github/ISSUE_TEMPLATE/` ou `.gitlab/issue_templates/`), git init (main + dev).

## 3. Personnaliser (obligatoire)

Le générateur pose des squelettes avec des `TODO`. Complète immédiatement ce qui est
connu grâce à la conversation :

- **README.md / CLAUDE.md** : remplacer les TODO de présentation par le périmètre réel
  décrit par l'utilisateur (fonctionnalités, contraintes, choix techniques).
- **docs/architecture.md** : premiers choix techniques connus.
- **Rien d'autre à adapter au layout** : le générateur ajuste lui-même les tableaux
  de tests, Docker, Storybook et les cibles Makefile selon layout/framework/options
  (blocs conditionnels des templates) — contrôler, ne pas réécrire.
- Le projet est **immédiatement fonctionnel** : `make install` puis `make lint`,
  `make test`, `make build` doivent passer (package.json, tsconfig, framework,
  Jest + Zod déjà câblés). Lancer `make install && make test` pour le prouver.

## 4. Vérification finale

- [ ] `make install && make lint && make test` passent dans `<target>`.
- [ ] `bash <target>/scripts/check-max-lines.sh <target>` passe.
- [ ] Les hooks sont exécutables (`ls -l <target>/.claude/hooks/`) et les subagents
      présents (`ls <target>/.claude/agents/` : opus-architect, opus-dev, haiku-mechanic).
- [ ] `git -C <target> log --oneline` montre le commit de bootstrap, branches `main` + `dev`.
- [ ] Résumer à l'utilisateur : structure créée, choix retenus, prochaines étapes
      (protections de branches sur GitHub/GitLab, premier `/create-feat`).

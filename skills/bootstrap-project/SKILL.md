---
name: bootstrap-project
description: Initialise un nouveau projet TypeScript/React avec la structure standard (README + docs/, CLAUDE.md, hooks & skills Claude Code, tests unitaire/integration/e2e/systeme, lint Biome + 300 lignes, CI GitHub ou GitLab). Pose les choix via AskUserQuestion puis exécute le générateur. À utiliser pour démarrer tout nouveau projet.
---

# Bootstrap d'un nouveau projet (`/bootstrap-project`)

Tu vas initialiser un projet avec la structure standard de l'utilisateur. Le gros du
travail est fait par le générateur `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh` —
ton rôle : recueillir les choix, l'exécuter, puis **personnaliser** le résultat.

## 1. Recueillir les choix (AskUserQuestion)

Pose ces questions (regroupe-les en un ou deux appels AskUserQuestion) :

1. **Nom du projet** (kebab-case) et **description courte** — si non fournis dans la
   demande initiale.
2. **Type de projet (layout)** : `front-back` (deux apps : front React + back API
   Node/TS), `single` (une seule app — typiquement Next.js avec ses API routes) ou
   `package` (librairie npm TypeScript, sans e2e/système).
3. **Framework front** (sauf package) : `Next.js` (recommandé — habitude de
   l'utilisateur) ou `Vite + React`.
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

## 2. Exécuter le générateur

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh \
  --name <nom> --desc "<description>" \
  --layout <front-back|single|package> --framework <nextjs|vite> \
  --ci <github|gitlab|none> [--no-storybook] [--no-tests-setup] [--acceptance] \
  --target <dossier>
```

**Ne pas passer `--owner`** : l'auteur est toujours le compte lié à la forge —
le générateur prend le compte connecté à la CLI GitHub (`gh api user`), à défaut
`git config user.name`. `--owner` ne sert qu'à forcer explicitement autre chose.

Le générateur crée : README.md, CLAUDE.md, docs/ (13 docs), .claude/ (hooks :
emplacement des tests, 300 lignes, dépendances, budget crédits, rappels doc/tests ;
settings.json ; skills `/create-issue`, `/create-feat`, `/merge-prod`), structure
de tests + configs Jest/Stryker/Cypress/Postman, `src/interfaces/` (entités `IXxx`
+ `types.ts`), `src/schemas/` (validation **Zod** des entrées),
`src/{components,views,hooks,services,utils}`, `shared/{interfaces,schemas}`
(layout front-back : entités et schémas partagés front/back), Makefile, biome.json,
`.nvmrc` (version Node unique), scripts/check-max-lines.sh, workflows CI, template
d'issue commun (`.github/ISSUE_TEMPLATE/` ou `.gitlab/issue_templates/`),
git init (main + dev).

## 3. Personnaliser (obligatoire)

Le générateur pose des squelettes avec des `TODO`. Complète immédiatement ce qui est
connu grâce à la conversation :

- **README.md / CLAUDE.md** : remplacer les TODO de présentation par le périmètre réel
  décrit par l'utilisateur (fonctionnalités, contraintes, choix techniques).
- **docs/architecture.md** : premiers choix techniques connus.
- **Layout `single` ou `package`** : adapter les tableaux de tests de CLAUDE.md et
  docs/testing.md aux chemins réels (`tests/...` à la racine, pas `front/`/`back/` ;
  pour un `package`, retirer les volets e2e/système/Cypress/Postman et Docker).
- Si l'utilisateur veut initialiser le code tout de suite : `create-next-app` /
  `create vite` dans le(s) bon(s) dossier(s), **installer Zod** (`npm install zod` —
  la validation des entrées via `schemas/` est obligatoire, voir CLAUDE.md), puis
  câbler les cibles réelles du Makefile (install, dev, lint, test-*, build) et commit
  sur une branche dédiée.

## 4. Vérification finale

- [ ] `bash <target>/scripts/check-max-lines.sh <target>` passe.
- [ ] Les hooks sont exécutables (`ls -l <target>/.claude/hooks/`).
- [ ] `git -C <target> log --oneline` montre le commit de bootstrap, branches `main` + `dev`.
- [ ] Résumer à l'utilisateur : structure créée, choix retenus, prochaines étapes
      (protections de branches sur GitHub/GitLab, premier `/create-feat`).

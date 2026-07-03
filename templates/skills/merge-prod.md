---
name: merge-prod
description: Mise en production de {{PROJECT_NAME}} — ouvre la PR dev → main après vérification complète de la CI/CD (lint, tests, e2e, système, build). L'assistant ne merge JAMAIS cette PR — validation humaine obligatoire ({{OWNER}}).
---

# Mise en production — {{PROJECT_NAME}} (`/merge-prod`)

Procédure de PR `dev` → `main`. Rappel des règles `CLAUDE.md` : l'assistant **ouvre et
remplit** la PR, mais **n'a pas le droit de la merger** — même tous checks verts.

## 0. Pré-vol

```bash
git fetch origin
git log origin/main..origin/dev --oneline   # ce qui part en prod — doit être non vide
```

- Aucun travail en cours non fusionné dans `dev` qui devrait partir avec ce train.
- `dev` est verte : **vérifier les derniers runs CI de `dev`** avant d'ouvrir la PR :
  ```bash
  gh run list --branch dev --limit 10       # tous les checks récents doivent être success
  ```
  (GitLab : `glab ci list --ref dev`.) Un run rouge → **corriger d'abord**, ne pas ouvrir la PR.

## 1. Ouvrir la PR

```bash
gh pr create --base main --head dev \
  --title "Release : <résumé court>" \
  --body "<liste des changements (issues fermées), impacts, points d'attention>"
```

## 2. Surveiller la CI de la PR

```bash
gh pr checks --watch
```

Les workflows `ci-main-*` (e2e, système, build) doivent **tous** passer.
En cas d'échec : corriger réellement (jamais affaiblir un test/workflow — règle
d'intégrité), retenter 2-3 fois, puis **escalader à {{OWNER}}** avec un diagnostic
clair si le blocage persiste.

## 3. Passer la main

- [ ] Tous les checks de la PR sont verts.
- [ ] Le corps de la PR liste les changements et les issues fermées.
- [ ] **STOP** : notifier {{OWNER}} que la PR est prête. **Ne pas merger.**

## Après le merge (par {{OWNER}})

```bash
git checkout dev && git pull origin dev && git merge origin/main   # si divergence (hotfix)
```

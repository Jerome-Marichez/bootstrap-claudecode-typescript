---
name: create-feat
description: Démarre une nouvelle fonctionnalité sur {{PROJECT_NAME}} — crée l'issue, la branche feature/<nom> depuis dev à jour, un worktree dédié, et délègue l'implémentation à un subagent dédié travaillant dans ce worktree. À utiliser au début de CHAQUE fonctionnalité (règle CLAUDE.md).
---

# Nouvelle fonctionnalité — {{PROJECT_NAME}} (`/create-feat`)

Cadre imposé par le `CLAUDE.md` : toute fonctionnalité = **une issue + une branche
dérivée de `dev` + un worktree dédié + un subagent dédié**. Jamais de commit direct
sur `dev` ni `main`. Le worktree isole la fonctionnalité : la copie de travail
principale reste propre et plusieurs fonctionnalités peuvent avancer en parallèle.

## Principes

- **Penser micro-features** : découper le besoin en unités **petites et livrables
  indépendamment** (une micro-feature = une issue = une branche = un worktree = un
  subagent = une PR). Si le besoin est gros, le découper AVANT de créer les issues.
- **Plan mode à privilégier pour l'orchestration** : entrer en plan mode pour découper
  en micro-features, valider le plan avec {{OWNER}}, puis dérouler les étapes ci-dessous
  pour chaque micro-feature. **Hors plan mode, le processus reste obligatoire** —
  issue → branche dérivée de dev → worktree → subagent dédié, sans exception.

## Étapes

1. **Clarifier le besoin** : titre court + description (quoi, pourquoi, critères
   d'acceptation). Si le besoin est flou, poser la question via AskUserQuestion.

2. **Créer l'issue** :
   ```bash
   gh issue create --title "<titre>" --body "<description + critères d'acceptation>"
   ```
   (GitLab : `glab issue create`.) Noter le numéro `#N`.

3. **Créer la branche depuis `dev` à jour + le worktree dédié** :
   ```bash
   git fetch origin
   git worktree add ../{{PROJECT_NAME}}-feature-<nom-court> -b feature/<nom-court-kebab> origin/dev
   ```
   La branche est créée directement depuis `origin/dev` et vit dans sa propre copie
   du dépôt — la copie principale n'est pas touchée.

4. **Déléguer à un subagent dédié** : lancer UN subagent (Agent tool) dont le prompt
   contient :
   - le **répertoire du worktree** comme unique zone de travail ;
   - l'**issue** (numéro, description, critères d'acceptation) ;
   - les règles du projet : tests unitaires **systématiques**, intégration/e2e à
     proposer, lint (`make lint`, 300 lignes max), mise à jour de la doc ;
   - la consigne finale : commits sur `feature/<nom>`, push, puis **PR vers `dev`**
     (`gh pr create --base dev`) avec `Closes #N` — et rendre compte (PR ouverte,
     état des checks).

5. **Suivre et intégrer** : à la fin du subagent, vérifier la PR, attendre les checks.
   Checks verts → auto-merge autorisé (règle CLAUDE.md).

## Nettoyage (après merge de la PR)

```bash
git worktree remove ../{{PROJECT_NAME}}-feature-<nom-court>
git branch -d feature/<nom-court>
```

## Vérification finale

- [ ] Issue créée et référencée par la PR (`Closes #N`).
- [ ] Branche dérivée de `dev` (`git merge-base --is-ancestor origin/dev HEAD`).
- [ ] Travail réalisé **dans le worktree**, par un **subagent dédié**.
- [ ] La mise en production reste du ressort de `/merge-prod`.

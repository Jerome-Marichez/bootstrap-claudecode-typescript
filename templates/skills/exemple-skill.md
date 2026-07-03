---
name: exemple-skill
description: Exemple de skill projet pour {{PROJECT_NAME}} — à remplacer par une vraie procédure récurrente (build, déploiement, fix connu). Supprimer ce dossier si inutile.
---

# Exemple de skill — {{PROJECT_NAME}}

Un skill = une **procédure récurrente** du projet, versionnée et rejouable par
Claude Code via `/exemple-skill`.

## Structure recommandée

1. **Pré-vol** : ce qui doit être vrai avant de commencer (env vars, services up…).
2. **Étapes** : commandes exactes, dans l'ordre, avec les vérifications entre chaque.
3. **Vérification finale** : comment prouver que la procédure a réussi.
4. **En cas d'échec** : diagnostics connus et remèdes.

> Exemple type : un skill `/build-full` qui enchaîne pipeline de build →
> déploiement → vérification e2e.

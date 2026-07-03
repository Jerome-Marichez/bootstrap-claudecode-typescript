---
name: create-issue
description: Crée une issue pour {{PROJECT_NAME}} (bug, feature, documentation ou autre) en remplissant OBLIGATOIREMENT le template d'issue commun du dépôt. À utiliser pour TOUTE création d'issue, y compris celles ouvertes par /create-feat. Jamais d'issue en texte libre, jamais d'emoji.
---

# Créer une issue — {{PROJECT_NAME}} (`/create-issue`)

Toute issue du projet suit le **template commun** du dépôt :
`.github/ISSUE_TEMPLATE/issue.md` (GitHub) ou `.gitlab/issue_templates/issue.md`
(GitLab). Interdictions : issue en texte libre, sections du template omises,
emoji dans le titre ou le corps.

## Étapes

1. **Qualifier la demande** : type (`bug`, `feature`, `documentation`, `autre`),
   résumé court, description. Si le type ou le besoin est flou, demander via
   AskUserQuestion.

2. **Remplir le template** : copier le fichier de template du dépôt et compléter
   **chaque** section (retirer la section « Pour un bug uniquement » si ce n'en
   est pas un). Les critères d'acceptation doivent être vérifiables.
   Titre : `<type>: <résumé court>` (ex. `bug: perte de la quantité panier`).

3. **Créer l'issue** :
   ```bash
   gh issue create --title "<type>: <résumé>" --body-file <fichier-rempli>
   ```
   (GitLab : `glab issue create --title "..." --description "$(cat <fichier>)"`.)
   Ajouter `--label <type>` si le label existe dans le dépôt. Noter le numéro `#N`.

## Vérification finale

- [ ] Le corps de l'issue reprend toutes les sections du template.
- [ ] Le titre suit `<type>: <résumé>` — sans emoji.
- [ ] Les critères d'acceptation sont testables.

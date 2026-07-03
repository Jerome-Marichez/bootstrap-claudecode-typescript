# Workflow Git

## Branches

| Branche | Rôle |
|---------|------|
| `main` | Production — stable, déployable, **protégée**. |
| `dev`  | Intégration — base des développements. |
| `feature/<nom>` | Une fonctionnalité = une branche, depuis `dev`. |
| `hotfix/<nom>`  | Correctif urgent, depuis `main`, fusionné dans `main` **et** `dev`. |

## Cycle d'une fonctionnalité

1. Créer une **issue** décrivant le besoin.
2. Créer `feature/<nom>` depuis `dev`.
3. Développer (tests unitaires systématiques, doc mise à jour).
4. Ouvrir une **PR vers `dev`** — description liée à l'issue.
5. CI verte → merge (auto-merge autorisé).
6. Mise en production : **PR `dev` → `main`**, fusion **réservée à un humain**.

## Protections de `main`

- Push direct interdit — PR obligatoire.
- Checks CI requis au vert.
- Revue approuvée obligatoire.

<!-- TODO : capturer ici la config effective (GitHub branch protection / GitLab protected branches). -->

## Conventions de commit

Format : `type: description courte` — types : `feat`, `fix`, `docs`, `test`,
`refactor`, `chore`, `ci`.

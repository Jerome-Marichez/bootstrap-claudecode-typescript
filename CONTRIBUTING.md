# Contribuer

Ce dépôt est un plugin Claude Code écrit en Bash qui génère des projets
TypeScript/React. Il encode des conventions de travail personnelles : les
propositions qui les changent en profondeur ont peu de chances d'être retenues,
les corrections de bugs et les améliorations de robustesse sont bienvenues.

## Prérequis

`bash`, `jq`, `make`, `git`. `shellcheck` pour le lint (`brew install shellcheck`),
`gh` pour les fonctions qui interrogent GitHub.

## Avant toute PR

```sh
./scripts/smoke-test.sh
```

C'est le seul harnais de test : il génère les 4 configurations de layout dans un
dossier temporaire et vérifie les invariants (tokens substitués, blocs
conditionnels filtrés, cibles Make câblées, comportement des hooks), lance
`shellcheck` et applique la règle des 300 lignes. Il doit être vert.

La CI le rejoue sur ubuntu **et** macOS : les hooks ont des branches BSD
(`date -j`/`-v`) que seul macOS exerce.

## Règles

1. **Bumper `.claude-plugin/plugin.json`** dans la même PR, en SemVer. C'est la
   source de vérité de la version : le workflow de release lit ce fichier au push
   sur `main` et ne fait rien si le tag existe déjà — sans bump, aucune release
   n'est publiée. Un job CI le vérifie.
   - MAJOR : structure générée différemment, option CLI retirée, config cassée.
   - MINOR : nouveau template, hook, skill ou option.
   - PATCH : correction de bug, docs, refactor sans changement visible.
2. **Conventional commits** (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`,
   `refactor:`), en français, avec scope quand c'est utile.
3. **300 lignes maximum par fichier**, y compris les `.sh` de ce dépôt — c'est la
   règle qu'il impose aux projets qu'il génère.
4. **Shellcheck sans finding** à la sévérité par défaut (`style`). Si un
   avertissement est un faux positif, le désactiver par une directive **ciblée et
   justifiée** en commentaire, jamais globalement.
5. **Toute correction de bug s'accompagne d'une assertion** dans
   `scripts/smoke-test.sh`, vérifiée comme échouant sur le code d'avant
   correctif — sinon elle ne prouve rien.

## Structure

- `.claude-plugin/` — manifeste du plugin (source de vérité de la version).
- `scripts/` — `bootstrap.sh` (générateur) et ses libs dans `scripts/lib/`,
  `smoke-test.sh`, `benchmark-routing.sh`.
- `templates/` — tout ce qui est copié dans les projets générés (hooks, agents,
  skills, docs, CI, code applicatif).
- `skills/bootstrap-project/` — le skill exposé par le plugin.
- `.github/workflows/` — `ci.yml` (smoke test, shellcheck, bump de version),
  `release.yml` (tag + release SemVer sur `main`).

## Templates

Les fichiers de `templates/` sont rendus par `render()` (`scripts/lib/render.sh`) :
substitution des tokens `{{...}}` puis filtrage des blocs conditionnels
`>>only:tag1,tag2` … `<<only`. **Ces blocs ne s'imbriquent pas** — utiliser un tag
composite si nécessaire.

# CLAUDE.md — bootstrap-claudecode-typescript

Instructions pour Claude Code lors de tout travail sur ce dépôt.

## Versioning et releases (obligatoire)

Toute modification destinée à `main` DOIT bumper la version dans
`.claude-plugin/plugin.json` en respectant le **semantic versioning** :

- **MAJOR** (`X.0.0`) : changement incompatible (structure des templates générée
  différemment, options CLI retirées, format de config cassé).
- **MINOR** (`0.X.0`) : nouvelle fonctionnalité rétro-compatible (nouveau
  template, nouveau hook, nouveau skill, nouvelle option).
- **PATCH** (`0.0.X`) : correction de bug, docs, refactor sans changement de
  comportement visible.

Le workflow `.github/workflows/release.yml` s'exécute à chaque push sur `main` :
il lit la version de `plugin.json` et crée automatiquement le tag `vX.Y.Z` et la
GitHub Release associée (avec les commits depuis le tag précédent comme notes).
Si le tag existe déjà, il ne fait rien — d'où l'obligation de bumper la version
dans le même commit/PR que le changement, sinon aucune release n'est publiée.

Checklist avant merge sur `main` :

1. Bumper `version` dans `.claude-plugin/plugin.json`.
2. Vérifier que le smoke test passe (`./scripts/smoke-test.sh`).
3. Message de commit en conventional commits (`feat:`, `fix:`, `docs:`, `chore:`).

## Structure du dépôt

- `.claude-plugin/` : manifeste du plugin (source de vérité de la version).
- `templates/` : fichiers `.tpl` et assets copiés dans les projets générés.
- `scripts/` : générateur et smoke test.
- `skills/`, `.claude/` : skills et settings Claude Code du plugin.
- `.github/workflows/` : `ci.yml` (smoke test ubuntu+macos), `release.yml`
  (tag + release semver sur main).

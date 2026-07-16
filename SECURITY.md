# Sécurité

## Signaler une vulnérabilité

Ouvrir un [avis de sécurité privé](https://github.com/Jerome-Marichez/bootstrap-claudecode-typescript/security/advisories/new)
plutôt qu'une issue publique. Réponse sous une quinzaine de jours ; ce dépôt est
maintenu sur du temps personnel, sans engagement de délai.

## Surface d'attaque

Ce plugin exécute du shell sur la machine de l'utilisateur et écrit dans le
dossier cible passé en `--target`. Ce qu'il faut savoir avant de l'installer :

- **`scripts/bootstrap.sh`** génère des fichiers dans `--target` et refuse
  d'écrire dans un dossier existant non vide. Il lance `git init` et un premier
  commit, sauf `--no-git`.
- **`templates/hooks/check-new-dependency.sh`**, installé dans les projets
  générés, interroge `registry.npmjs.org` et `api.github.com` à chaque
  installation de dépendance. Il utilise le jeton de `gh auth token` ou
  `$GITHUB_TOKEN` s'il en trouve un, en lecture seule. Ce jeton est passé en
  argument à `curl`, donc brièvement visible dans la table des processus locale.
- **`templates/hooks/route-task.sh`** peut invoquer `npx ccusage` (résultat mis
  en cache 10 min) uniquement si `CREDITS_LIMIT_TOKENS` est défini, et journalise
  la classification de chaque prompt dans `.claude/route-task.log` — classe et
  nombre de mots, jamais le contenu du prompt.
- **`scripts/benchmark-routing.sh`** exécute les commandes passées via
  `--install-cmd`/`--lint-cmd`/`--test-cmd` telles quelles dans un shell, et
  lance `claude` avec `--dangerously-skip-permissions`. C'est un outil de mesure
  destiné à un usage local délibéré, pas à une exécution automatisée.

Aucun secret n'est stocké dans ce dépôt. Les projets générés ignorent `.env*` par
défaut.

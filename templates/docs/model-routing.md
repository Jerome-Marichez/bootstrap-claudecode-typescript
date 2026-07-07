# Routage de modèles (Claude Code)

Chaque demande n'a pas besoin du même modèle : payer un modèle frontière pour un
renommage est du gaspillage, confier une migration à un petit modèle est une perte
de qualité. Le projet embarque un routage **sans perte de précision** : classification
heuristique instantanée + subagents pré-définis + escalade.

## Mécanisme

1. **`.claude/hooks/route-task.sh`** (UserPromptSubmit) classifie le prompt
   (regex FR/EN + longueur, zéro appel réseau, zéro latence) et **injecte une
   recommandation** de subagent dans le contexte.
2. **`.claude/agents/`** définit trois subagents — le modèle **et** le niveau
   d'effort sont portés par leur frontmatter (`model:`, `effort:`), mécanisme
   natif de Claude Code :

| Subagent | Modèle | Effort | Tâches |
|----------|--------|--------|--------|
| `opus-architect` | opus | xhigh | architecture, conception, migrations, sécurité, auth, paiement, concurrence, debugging profond, questions ouvertes (« pourquoi », « comment devrait-on ») |
| `opus-dev` | opus | medium | features, refactoring ciblé, bugfix non trivial, tests — **et toute la zone grise** |
| `haiku-mechanic` | haiku | — | doc, renommages, formatage, commits, recherches de fichiers |

3. Le modèle principal **peut outrepasser** la recommandation (il voit tout le
   contexte de la session, pas seulement le prompt) — c'est un second classifieur
   gratuit. Consigne : dans le doute, un cran **au-dessus**.

## Garde-fous anti-perte de précision

- **Défaut = vers le haut.** On ne route *vers le bas* que sur signal positif net
  (tâche mécanique, courte, sans signal métier). La zone grise va à `opus-dev`,
  jamais à `haiku-mechanic`. (Asymétrie clé de la littérature routing : biaiser le
  seuil vers le modèle fort coûte peu en tokens, l'inverse coûte cher en qualité.)
- **Escalade (cascade).** Les prompts de `opus-dev` et `haiku-mechanic` imposent
  de répondre `ESCALATE: <raison>` si la tâche les dépasse ; le modèle principal
  re-délègue alors un niveau au-dessus. Une décision de routage n'est donc jamais
  définitive.
- **Signaux de risque prioritaires.** sécurité, auth, paiement, migration,
  concurrence → toujours `opus-architect`, quelle que soit la taille du prompt.
- **L'effort porte l'économie, pas la qualité du modèle.** Les deux paliers hauts
  restent sur Opus — seule la profondeur de raisonnement varie (`xhigh` pour
  l'architecture, recommandation officielle pour le code ; `medium` pour le
  développement courant). Les économies viennent de l'effort réduit et de Haiku
  sur le mécanique, jamais d'un modèle plus faible sur une tâche de fond.
- **Override utilisateur.** Préfixer le prompt par `!!` désactive le routage pour
  ce prompt. Le hook ne bloque jamais rien.
- **Fail-open.** Toute erreur du hook (jq absent, ccusage KO) → aucune injection,
  comportement normal de la session.

## Budget crédits

Si `CREDITS_LIMIT_TOKENS` (plafond de tokens du bloc de facturation 5 h) est défini
dans l'environnement, le hook lit la consommation via `ccusage` — **mise en cache
10 minutes** (aucun appel réseau à chaque prompt) :

- **> 50 % consommés et reset < 2 h** → recommandation plafonnée à `opus-dev`
  (effort medium, pas de xhigh) jusqu'au reset ;
- **< 50 % consommés et reset < 1 h** → message : marge disponible, modèle fort
  utilisable sans compter.

## Journal et évaluation

Chaque classification est journalisée dans `.claude/route-task.log` (JSONL :
timestamp, classe, subagent, taille du prompt — gitignoré). Règle d'évolution :
ne **descendre** un type de tâche d'un niveau que si le journal montre qu'il
n'escalade jamais — « step down only when measured ».

## Sources

- Subagents Claude Code (frontmatter `model`, `effort`) :
  <https://code.claude.com/docs/en/sub-agents>
- Hooks Claude Code (UserPromptSubmit, `additionalContext`) :
  <https://code.claude.com/docs/en/hooks>
- Paramètre effort (recommandations par modèle) :
  <https://platform.claude.com/docs/en/build-with-claude/effort>
- RouteLLM (routage par classifieur, seuil biaisé vers le fort) :
  <https://arxiv.org/abs/2406.18665>
- Cascade routing (routage + escalade dominent chaque approche seule) :
  <https://arxiv.org/abs/2410.10347>
- Hook de routage communautaire comparable :
  <https://github.com/tzachbon/claude-model-router-hook>

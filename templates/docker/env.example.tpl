# .env.example — {{PROJECT_NAME}}
# Modèle documenté des variables d'environnement : copier en `.env` (gitignoré,
# JAMAIS commité) et compléter. Toute variable lue par le code est validée par un
# schéma Zod (schemas/env.schema.ts) avant usage — voir CLAUDE.md.

# >>only:front-back
# Ports exposés par docker compose
FRONT_PORT=3000
BACK_PORT=3001
# <<only
# >>only:single
# Port exposé par docker compose
APP_PORT=3000
# <<only

# Exemple : URL d'API, secrets… (documenter chaque variable ajoutée)
# API_URL=http://localhost:3001

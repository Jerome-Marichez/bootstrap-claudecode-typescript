# docker-compose.yml — {{PROJECT_NAME}}
# Stack conteneurisée : make docker-up / make logs / make docker-down.
# Secrets et variables : .env (gitignoré) — modèle documenté dans .env.example.
services:
# >>only:front-back
  front:
    build: ./front
    ports:
      - "${FRONT_PORT:-3000}:3000"
    env_file:
      - path: .env
        required: false
    depends_on:
      - back
  back:
    build: ./back
    ports:
      - "${BACK_PORT:-3001}:3001"
    environment:
      PORT: 3001
    env_file:
      - path: .env
        required: false
# <<only
# >>only:single
  app:
    build: .
    ports:
      - "${APP_PORT:-3000}:3000"
    env_file:
      - path: .env
        required: false
# <<only

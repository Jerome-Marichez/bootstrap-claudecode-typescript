# Makefile — {{PROJECT_NAME}}
# Interface de commandes unique (local + CI). `make help` liste les cibles.

.DEFAULT_GOAL := help
.PHONY: help install dev lint test test-unit test-int test-e2e test-system docker-up docker-down logs

help: ## Liste les commandes disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

install: ## Installe les dépendances (front + back)
	@echo "TODO : npm ci dans front/ et back/ (ou à la racine selon le layout)"

dev: ## Démarrage local en mode développement
	@echo "TODO : démarrer l'app (next dev / vite dev + back)"

lint: ## Biome sur tout le dépôt + limite 300 lignes/fichier
	npx @biomejs/biome check .
	./scripts/check-max-lines.sh

test: test-unit test-int ## Tests unitaires + intégration (rapides)

test-unit: ## Tests unitaires (front + back)
	@echo "TODO : jest (tests/unitaire)"

test-int: ## Tests d'intégration (front + back)
	@echo "TODO : jest (tests/integration)"

test-e2e: ## Tests e2e navigateur (Cypress headless)
	@echo "TODO : cypress run"

test-system: ## Tests système back (vrai serveur HTTP + Postman)
	@echo "TODO : jest (systeme) ; newman run back/tests/systeme/postman_collection.json"

test-mutation: ## Tests de mutation (Stryker) — qualité des tests unitaires/intégration
	@echo "TODO : npx stryker run"

test-acceptance: ## Tests d'acceptation / UAT (si activés)
	@echo "TODO : node --test tests/acceptance/"

storybook: ## Storybook en local (http://localhost:6006)
	@echo "TODO : npm run storybook (après npx storybook@latest init)"

storybook-build: ## Build statique Storybook
	@echo "TODO : npm run build-storybook"

docker-up: ## Build + démarrage de la stack conteneurisée
	docker compose up -d --build

docker-down: ## Arrêt des conteneurs
	docker compose down

logs: ## Logs agrégés des conteneurs
	docker compose logs -f

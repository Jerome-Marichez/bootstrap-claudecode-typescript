# Makefile — {{PROJECT_NAME}}
# Interface de commandes unique (local + CI). `make help` liste les cibles.

.DEFAULT_GOAL := help
.PHONY: help install dev build lint test test-unit test-int test-mutation
# >>only:e2e
.PHONY: test-e2e
# <<only
# >>only:system
.PHONY: test-system
# <<only
# >>only:acceptance
.PHONY: test-acceptance
# <<only
# >>only:storybook
.PHONY: storybook storybook-build
# <<only
# >>only:docker
.PHONY: docker-up docker-down logs
# <<only

help: ## Liste les commandes disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

lint: ## Biome sur tout le dépôt + limite 300 lignes/fichier
	npx @biomejs/biome@{{BIOME_VERSION}} check .
	./scripts/check-max-lines.sh

test: test-unit test-int ## Tests unitaires + intégration (rapides)

# >>only:front-back
install: ## Installe les dépendances (front + back)
	cd front && npm install
	cd back && npm install

dev: ## Démarrage local en mode développement
	@echo "Deux terminaux : « cd front && npm run dev » et « cd back && npm run dev » — ou make docker-up."

build: ## Build de production (front + back)
	cd front && npm run build
	cd back && npm run build

test-unit: ## Tests unitaires (front + back)
	cd front && npx jest tests/unitaire --passWithNoTests
	cd back && npx jest tests/unitaire --passWithNoTests

test-int: ## Tests d'intégration (front + back)
	cd front && npx jest tests/integration --passWithNoTests
	cd back && npx jest tests/integration --passWithNoTests

test-e2e: ## Tests e2e navigateur (Cypress headless) — stack démarrée au préalable
	cd front && npx cypress run

test-system: ## Tests système back (vrai serveur HTTP via listen(0))
	cd back && npx jest tests/systeme --passWithNoTests
	@echo "Collection Postman rejouable : npx newman run back/tests/systeme/postman_collection.json (stack démarrée)"

test-mutation: ## Tests de mutation (Stryker) — qualité des tests unitaires/intégration
	cd front && npx stryker run
	cd back && npx stryker run
# <<only
# >>only:single,package
install: ## Installe les dépendances
	npm install

dev: ## Démarrage local en mode développement
	npm run dev

build: ## Build de production
	npm run build

test-unit: ## Tests unitaires
	npx jest tests/unitaire --passWithNoTests

test-int: ## Tests d'intégration
	npx jest tests/integration --passWithNoTests

test-mutation: ## Tests de mutation (Stryker) — qualité des tests unitaires/intégration
	npx stryker run
# <<only
# >>only:single
test-e2e: ## Tests e2e navigateur (Cypress headless) — stack démarrée au préalable
	npx cypress run

test-system: ## Tests système (vrai serveur HTTP via listen(0))
	npx jest tests/systeme --passWithNoTests
	@echo "Collection Postman rejouable : npx newman run tests/systeme/postman_collection.json (stack démarrée)"
# <<only
# >>only:postman
test-system: ## Tests système API (Postman/newman — --postman)
	npx jest tests/systeme --passWithNoTests
	@echo "Collection Postman rejouable : npx newman run tests/systeme/postman_collection.json (API démarrée)"
# <<only
# >>only:acceptance
test-acceptance: ## Tests d'acceptation / UAT (runner Node natif)
	node --test tests/acceptance/
# <<only
# >>only:storybook
storybook: ## Storybook en local (http://localhost:6006) — après npx storybook@latest init
	@if [ -d front ]; then cd front && npm run storybook; else npm run storybook; fi

storybook-build: ## Build statique Storybook
	@if [ -d front ]; then cd front && npm run build-storybook; else npm run build-storybook; fi
# <<only
# >>only:docker
docker-up: ## Build + démarrage de la stack conteneurisée
	docker compose up -d --build

docker-down: ## Arrêt des conteneurs
	docker compose down

logs: ## Logs agrégés des conteneurs
	docker compose logs -f
# <<only

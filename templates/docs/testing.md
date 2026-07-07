# Stratégie de tests

Les tests **conditionnent la fusion** d'une PR vers `dev` (voir le
[workflow Git](./git-workflow.md)) : tant qu'un niveau échoue, la PR n'est pas fusionnée.

## Niveaux de tests

<!-- >>only:front-back -->
| Niveau | Côté | Objet | Outil | Emplacement / nommage |
|--------|------|-------|-------|-----------------------|
| **unitaire** | front | composants, hooks, logique pure | **Jest + React Testing Library** | `front/tests/unitaire/**/*.spec.ts(x)` |
| **intégration** | front | plusieurs unités ensemble (composant ↔ service ↔ vraie frontière HTTP pilotée par fixtures) | **Jest + RTL** (+ MSW à la frontière réseau) | `front/tests/integration/**/*.integration.spec.ts(x)` |
| **e2e** | front | parcours **navigateur** contre l'app réelle (front + back) | **Cypress** | `front/tests/e2e/**/*.cy.ts` |
| **unitaire** | back | services, validation, logique métier pure | **Jest** | `back/tests/unitaire/**/*.test.ts` |
| **intégration** | back | routes → services → repositories → **base de test dédiée** | **Jest + Supertest** | `back/tests/integration/**/*.test.ts` |
| **système** | back | **vrai serveur HTTP** (`app.listen(0)`, port éphémère) appelé par un client réel (`fetch`) — bout en bout **sans navigateur** | **Jest + fetch** | `back/tests/systeme/**/*.test.ts` |
| **système API (rejouable)** | back | validation documentée de l'API de bout en bout | **Postman** (collection versionnée) | `back/tests/systeme/postman_collection.json` |
<!-- <<only -->
<!-- >>only:single -->
| Niveau | Objet | Outil | Emplacement / nommage |
|--------|-------|-------|-----------------------|
| **unitaire** | composants, hooks, logique pure | **Jest + React Testing Library** | `tests/unitaire/**/*.spec.ts(x)` |
| **intégration** | plusieurs unités ensemble (composant ↔ service ↔ vraie frontière HTTP pilotée par fixtures) | **Jest + RTL** (+ MSW à la frontière réseau) | `tests/integration/**/*.integration.spec.ts(x)` |
| **e2e** | parcours **navigateur** contre l'app réelle | **Cypress** | `tests/e2e/**/*.cy.ts` |
| **système** | **vrai serveur HTTP** (`listen(0)`, port éphémère) appelé par un client réel (`fetch`) — bout en bout **sans navigateur** | **Jest + fetch** | `tests/systeme/**/*.test.ts` |
| **système API (rejouable)** | validation documentée de l'API de bout en bout | **Postman** (collection versionnée) | `tests/systeme/postman_collection.json` |
<!-- <<only -->
<!-- >>only:package -->
| Niveau | Objet | Outil | Emplacement / nommage |
|--------|-------|-------|-----------------------|
| **unitaire** | fonctions, services, logique pure | **Jest** | `tests/unitaire/**/*.test.ts` |
| **intégration** | plusieurs unités ensemble, frontières pilotées par fixtures | **Jest** | `tests/integration/**/*.test.ts` |
<!-- <<only -->
<!-- >>only:postman -->
| **système API (rejouable)** | validation documentée de l'API exposée par la librairie | **Jest** + **Postman** (collection versionnée) | `tests/systeme/**/*.test.ts`, `tests/systeme/postman_collection.json` |
<!-- <<only -->
<!-- >>only:acceptance -->

**Acceptation / non-fonctionnel** : parcours métier de bout en bout **et** volets
**UAT** (disponibilité, sécurité, performance, robustesse) sur la stack réellement
lancée — runner Node natif (`node:test` + `fetch`), dans `tests/acceptance/` et
`tests/acceptance/uat/<catégorie>/`.
<!-- <<only -->

## Qualité des tests — mutation testing (Stryker)

**Stryker** mesure la capacité des tests unitaires/intégration à détecter de vraies
régressions (score de mutation, seuils dans `stryker.config.json` — le build casse
sous le seuil `break`). Lancer : `make test-mutation`.

## Règles

- **Pas de mocks des données métier** : les frontières (HTTP, base) sont pilotées avec
  des **fixtures réalistes** ; les services métier réels collaborent entre eux.
- **Base de test dédiée** (intégration back) : jamais la base de développement/production ;
  base propre entre les suites ; garde-fou anti-prod dans le setup.
- **e2e réservé aux parcours navigateur** ; le bout-en-bout back sans navigateur est le
  niveau **système**.
- **Couverture** : seuil défini dans la config de test — la CI échoue en dessous.
  <!-- TODO : fixer le seuil (ex. 90 %). -->

## Commandes

```bash
make test             # unitaires + intégration
make test-unit        # unitaires (Jest)
make test-int         # intégration (Jest)
<!-- >>only:e2e -->
make test-e2e         # Cypress headless
<!-- <<only -->
<!-- >>only:system -->
make test-system      # système (Jest + fetch ; collection Postman rejouable)
<!-- <<only -->
make test-mutation    # Stryker (score de mutation)
<!-- >>only:acceptance -->
make test-acceptance  # acceptation / UAT
<!-- <<only -->
```

# Storybook

<!-- TODO : compléter après `npx storybook@latest init`. -->

## Rôle

Catalogue vivant des composants React : développement isolé, documentation visuelle,
base pour les revues design et les tests visuels.

## Conventions

- Une story par composant réutilisable : `<Composant>.stories.tsx`, **à côté du composant**.
- Chaque story couvre les **états significatifs** (défaut, chargement, erreur, vide, désactivé).
- Les stories utilisent des **fixtures réalistes** (jamais de lorem ipsum pour les données métier).

> **Sans Storybook** : si le projet n'active pas Storybook, ce sont les **tests
> unitaires (RTL)** qui couvrent ces mêmes états significatifs — ils tiennent lieu
> de catalogue. Le routage vers `opus-frontend` reste conditionnel à la présence de
> Storybook (voir [`model-routing.md`](./model-routing.md)).

## Commandes

```bash
make storybook          # démarrage local (http://localhost:6006)
make storybook-build    # build statique (déployable)
```

## Composants couverts

| Composant | Stories | États couverts |
|-----------|---------|----------------|
| _TODO_ | | |

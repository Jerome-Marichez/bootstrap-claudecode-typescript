# Architecture

<!-- TODO : compléter à mesure que le projet prend forme. -->

## Vue d'ensemble

Décrire ici : les grands blocs (front React, back API, base de données), leurs
responsabilités et les flux entre eux (schéma bienvenu).

<!-- >>only:package -->
## Librairie (TypeScript)

- **Point d'entrée unique** : `src/index.ts` — tout ce qui y est exporté est l'API
  publique (build `tsup`, exports ESM + CJS + types dans `package.json`).
- **Découpage** : `src/services/` (logique), `src/utils/` (helpers purs),
  `src/interfaces/` (entités `IXxx` + `types.ts`), `src/schemas/` (validation Zod
  des entrées externes).
- **SemVer strict** : toute rupture d'API publique = version majeure.
<!-- <<only -->
<!-- >>only:front-back,single -->
## Front ({{FRAMEWORK}} + TypeScript)

- **Organisation** : par domaine **métier**, pas par type technique. Quand l'app
  grandit, chaque domaine vit sous `src/@<domaine>/` (ex. `@core` = socle applicatif,
  `@vitrine` = site public, `@shared` = transverse) et porte ses propres
  `components/`, `hooks/`, `services/`, `utils/`, `interfaces/`.
- **Composant = un dossier** : `components/Button/index.tsx` + styles et assets
  colocalisés (`button.module.css`). Composants **purs** par défaut ; ceux qui portent
  des effets (store, réseau, auth) sont isolés dans `_notPure/`.
- **`views/` vs `pages/`** : `pages/` (ou `app/`) ne fait que le **routage** ; les
  sections d'écran composées vivent dans `src/views/<domaine>/`.
- **Nommage des fichiers** : PascalCase pour les **composants** et **vues**
  (`Button.tsx`, `HomeView.tsx`) ; **minuscules** pour tout le reste
  (services, hooks, utilitaires, configs).
- **Nommage des symboles** : PascalCase pour les **interfaces** (`IProduct`), les
  **composants `.tsx`** et les **classes métier** de `services/` (`CartService`) ;
  camelCase pour tout le reste (fonctions, variables, hooks).
- **`services/` vs hooks** : la logique **métier** vit dans `src/services/`
  (règles de gestion, appels API) ; les **hooks React** ne portent que la logique
  de **rendu** (état d'UI, orchestration des services pour les composants).
- **`src/utils/`** : utilitaires transverses (helpers purs, formatage) — sans état,
  sans logique métier.
- **Interfaces & types** : `src/interfaces/` regroupe **toutes** les interfaces
  d'entités — une interface par fichier, nom préfixé par `I` (`IProduct`, `IUser`…) ;
  `src/interfaces/types.ts` regroupe les **alias de types purs** (unions, utilitaires),
  jamais d'interface dedans.
- **Validation des entrées — Zod (obligatoire)** : toute entrée externe (formulaire,
  réponse d'API, query params, env) passe par un schéma Zod de `src/schemas/`
  (`product.schema.ts`) ; type dérivé par `z.infer`, jamais de cast direct.
- **État** : privilégier l'état local + hooks ; un store global uniquement si justifié.
- **Composants** : max 300 lignes — extraire sous-composants et hooks personnalisés.
<!-- <<only -->
<!-- >>only:front-back -->

## Partage front/back

- **`shared/`** à la racine : `shared/interfaces/` (entités `IXxx` communes) et
  `shared/schemas/` (schémas Zod communs) — une entité partagée n'est **jamais
  dupliquée** côté front et côté back.

## Back

- **Découpage** : routes → services → repositories.
- **Validation — Zod (obligatoire)** : chaque body/query/webhook est validé à la
  frontière par un schéma de `back/src/schemas/` (ou `shared/schemas/` si partagé).
<!-- <<only -->
<!-- >>only:single -->

## API (routes du framework)

- **Découpage** : routes → services → repositories — les routes ne portent aucune
  logique métier.
- **Validation — Zod (obligatoire)** : chaque body/query/webhook est validé à la
  frontière par un schéma de `src/schemas/`.
<!-- <<only -->

## Choix techniques et justifications

| Choix | Alternatives considérées | Justification |
|-------|--------------------------|---------------|
| _TODO_ | | |

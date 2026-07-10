# Design & UI

<!-- TODO : compléter avec la charte du projet (bibliothèque UI, tokens réels). -->

## Principes

- **Cohérence** : composants réutilisables, tokens de design centralisés
  (couleurs, espacements, typographie).
- **Responsive** : mobile-first, breakpoints documentés.
- **Thème** : clair/sombre si pertinent.

## Bibliothèque UI

Choisir **une** bibliothèque et s'y tenir (ne pas mélanger plusieurs systèmes) :

| Choix | Notes |
|-------|-------|
| _TODO (ex. shadcn/ui, PrimeReact, MUI…)_ | |

## Stratégie de style

Une **seule** stratégie par projet, cohérente avec [`frontend-practices.md`](./frontend-practices.md) :

| Stratégie | Quand | Convention |
|-----------|-------|------------|
| **CSS Modules** | style scopé, sans lib CSS-in-JS | `Composant/index.module.css` co-localisé, classes en **BEM** |
| **styled / emotion** | design system type MUI | thème centralisé, pas de style en dur |
| **Utilitaire (Tailwind…)** | prototypage rapide, design tokens intégrés | classes utilitaires, `@apply` pour les motifs récurrents |

Règles communes : style **co-localisé** avec le composant, **mobile-first**, valeurs
issues des **tokens** ci-dessous (jamais de couleur/espacement en dur).

## Breakpoints

| Nom | Largeur min | Usage |
|-----|-------------|-------|
| `sm` | 640px | mobile paysage |
| `md` | 768px | tablette |
| `lg` | 1024px | desktop |
| `xl` | 1280px | large desktop |

<!-- Ajuster aux breakpoints réels de la bibliothèque UI retenue. -->

## Tokens

| Token | Valeur (exemple) | Usage |
|-------|------------------|-------|
| `color-primary` | `#2563eb` | actions principales, liens |
| `color-danger` | `#dc2626` | erreurs, suppression |
| `space-unit` | `8px` | base des espacements (multiples : 8/16/24…) |
| `radius-base` | `6px` | arrondis de cartes/boutons |
| `font-body` | `system-ui, sans-serif` | texte courant |

<!-- Remplacer par les tokens réels du projet. -->

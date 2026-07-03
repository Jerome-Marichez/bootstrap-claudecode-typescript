# Accessibilité

<!-- TODO : compléter avec les audits réalisés. -->

## Objectif

Conformité **WCAG 2.1 AA** sur les parcours principaux.

## Règles pour le front React

- HTML **sémantique** d'abord (`nav`, `main`, `button`…) ; ARIA seulement en complément.
- **Navigation clavier** complète : focus visible, ordre logique, pas de piège de focus.
- **Formulaires** : chaque champ a un `label` associé ; erreurs annoncées (`aria-live`).
- **Contrastes** : ratio ≥ 4.5:1 pour le texte courant.
- **Images** : `alt` pertinent (ou vide si décorative).

## Vérification

- Lint accessibilité (règles a11y de Biome).
- Audit manuel clavier + lecteur d'écran sur les parcours critiques.

| Parcours | Audit | État |
|----------|-------|------|
| _TODO_ | | |

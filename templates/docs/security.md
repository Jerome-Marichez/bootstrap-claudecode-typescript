# Sécurité

<!-- TODO : compléter selon les besoins réels du projet. -->

## Règles de base

- **Secrets** : jamais en dur ni commités — variables d'environnement (`.env` gitignoré,
  `.env.example` documenté). Le serveur **refuse de démarrer** si un secret obligatoire manque
  (pas de valeur par défaut pour un secret).
- **Authentification** : JWT signé (secret fort, `openssl rand -hex 32`), expiration courte.
- **Validation des entrées** : systématique à la frontière API (Zod ou équivalent).
- **Dépendances** : `npm audit` surveillé ; pas d'ajout de dépendance sans justification.
- **Moindre privilège** : les opérations d'écriture sensibles réservées aux rôles autorisés.

## Points d'attention

| Sujet | État | Notes |
|-------|------|-------|
| Gestion des secrets | _TODO_ | |
| Auth / sessions | _TODO_ | |
| Headers HTTP (CORS, CSP…) | _TODO_ | |
| Chiffrement en transit (TLS) | _TODO_ | |

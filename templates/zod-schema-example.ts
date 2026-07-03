// exemple.schema.ts — {{PROJECT_NAME}}
// Un schéma Zod par entrée externe (body/query d'API, formulaire, webhook, env).
// Le type TypeScript est TOUJOURS dérivé du schéma (z.infer), jamais écrit à la main —
// et il doit rester aligné avec l'interface d'entité correspondante (interfaces/IXxx.ts).
// Convention : docs/architecture.md. Supprimer ce fichier dès le premier vrai schéma.

// import { z } from 'zod'
//
// export const productSchema = z.object({
//   id: z.number().int().positive(),
//   name: z.string().min(1),
//   price: z.number().nonnegative(),
// })
//
// export type ProductInput = z.infer<typeof productSchema>

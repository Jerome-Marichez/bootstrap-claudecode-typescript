// Test unitaire d'exemple — {{PROJECT_NAME}}
// Valide la chaîne Jest + ts-jest + tsconfig et illustre la convention :
// validation Zod des entrées, type dérivé par z.infer (jamais de cast direct).
// Supprimer ce fichier dès le premier vrai test. Référence : docs/testing.md.
import { z } from 'zod'

const exempleSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1),
})

type ExempleInput = z.infer<typeof exempleSchema>

describe('exemple — validation Zod des entrées', () => {
  it('accepte une entrée valide', () => {
    const input: ExempleInput = { id: 1, name: '{{PROJECT_NAME}}' }
    expect(exempleSchema.parse(input)).toEqual(input)
  })

  it('rejette une entrée invalide', () => {
    expect(() => exempleSchema.parse({ id: -1, name: '' })).toThrow()
  })
})

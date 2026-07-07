// src/main.tsx — {{PROJECT_NAME}}
// Point d'entrée Vite. Squelette : remplacer le contenu par la vraie app
// (vues composées depuis src/views/, composants dans src/components/).
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

const root = document.getElementById('root')
if (!root) throw new Error('Élément #root introuvable dans index.html')

createRoot(root).render(
  <StrictMode>
    <h1>{{PROJECT_NAME}}</h1>
  </StrictMode>,
)

// Configuration Cypress — {{PROJECT_NAME}} (e2e navigateur)
// Specs : tests/e2e/**/*.cy.ts — contre la stack réellement lancée.
import { defineConfig } from 'cypress'

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000', // TODO : port réel du front
    specPattern: 'tests/e2e/**/*.cy.ts',
    supportFile: false,
    video: false,
  },
})

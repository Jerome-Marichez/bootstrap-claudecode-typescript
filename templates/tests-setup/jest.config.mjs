// Configuration Jest — {{PROJECT_NAME}}
// Unitaire : tests/unitaire/**  —  Intégration : tests/integration/**
// TODO : adapter transform/preset au scaffolding réel (ts-jest, next/jest ou babel).

/** @type {import('jest').Config} */
export default {
  testEnvironment: 'node', // 'jsdom' côté front (composants React)
  roots: ['<rootDir>/tests'],
  testMatch: [
    '**/tests/unitaire/**/*.(test|spec).ts?(x)',
    '**/tests/integration/**/*.(test|spec).ts?(x)',
    '**/tests/systeme/**/*.test.ts',
  ],
  transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.json' }] },
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 },
  },
}

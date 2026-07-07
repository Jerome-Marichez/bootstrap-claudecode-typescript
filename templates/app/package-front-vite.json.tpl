{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "description": "{{PROJECT_DESC}}",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "start": "vite preview --host",
    "test": "jest --passWithNoTests"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "zod": "^4.0.0"
  },
  "devDependencies": {
    "@biomejs/biome": "{{BIOME_VERSION}}",
>>only:tests-setup
    "@stryker-mutator/core": "^9.0.0",
    "@stryker-mutator/jest-runner": "^9.0.0",
    "cypress": "^15.0.0",
<<only
    "@testing-library/react": "^16.3.0",
    "@types/jest": "^30.0.0",
    "@types/node": "^24.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^5.0.0",
    "jest": "^30.0.0",
    "jest-environment-jsdom": "^30.0.0",
    "ts-jest": "^29.4.0",
    "typescript": "^5.9.0",
    "vite": "^7.0.0"
  }
}

{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "description": "{{PROJECT_DESC}} — API back",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc -p tsconfig.json",
    "start": "node dist/index.js",
    "test": "jest --passWithNoTests"
  },
  "dependencies": {
    "zod": "^4.0.0"
  },
  "devDependencies": {
    "@biomejs/biome": "{{BIOME_VERSION}}",
>>only:tests-setup
    "@stryker-mutator/core": "^9.0.0",
    "@stryker-mutator/jest-runner": "^9.0.0",
<<only
    "@types/jest": "^30.0.0",
    "@types/node": "^24.0.0",
    "jest": "^30.0.0",
    "ts-jest": "^29.4.0",
    "tsx": "^4.19.0",
    "typescript": "^5.9.0"
  }
}

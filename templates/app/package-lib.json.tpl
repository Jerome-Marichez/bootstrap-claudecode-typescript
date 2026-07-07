{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "description": "{{PROJECT_DESC}}",
  "author": "{{OWNER}}",
  "license": "MIT",
  "main": "./dist/index.js",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.mjs",
      "require": "./dist/index.js"
    }
  },
  "files": ["dist"],
  "scripts": {
    "dev": "tsup src/index.ts --format esm,cjs --dts --watch",
    "build": "tsup src/index.ts --format esm,cjs --dts",
    "test": "jest --passWithNoTests",
    "prepublishOnly": "npm run build"
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
    "tsup": "^8.0.0",
    "typescript": "^5.9.0"
  }
}

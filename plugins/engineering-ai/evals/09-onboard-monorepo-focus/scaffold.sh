#!/usr/bin/env bash
# Fixture for eval case 09: pnpm/turbo monorepo where each package has its own test runner.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p packages/web/src packages/api/src
cat > package.json <<'JSON'
{
  "name": "acme-monorepo",
  "private": true,
  "packageManager": "pnpm@9.12.0",
  "scripts": {
    "test": "turbo run test",
    "lint": "turbo run lint"
  },
  "devDependencies": { "turbo": "2.1.0" }
}
JSON
cat > pnpm-workspace.yaml <<'YAML'
packages:
  - "packages/*"
YAML
echo '{ "tasks": { "test": {}, "lint": {} } }' > turbo.json
touch pnpm-lock.yaml
cat > packages/web/package.json <<'JSON'
{
  "name": "@acme/web",
  "private": true,
  "scripts": {
    "test": "vitest run",
    "lint": "eslint src",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": { "react": "18.3.1" },
  "devDependencies": { "vitest": "2.1.0", "eslint": "9.12.0", "typescript": "5.6.2" }
}
JSON
echo 'export const App = () => null;' > packages/web/src/App.tsx
cat > packages/api/package.json <<'JSON'
{
  "name": "@acme/api",
  "private": true,
  "scripts": {
    "test": "jest",
    "lint": "eslint src"
  },
  "dependencies": { "express": "4.21.0" },
  "devDependencies": { "jest": "29.7.0" }
}
JSON
echo 'module.exports = {};' > packages/api/src/server.js
git add -A && git commit -qm "initial commit"

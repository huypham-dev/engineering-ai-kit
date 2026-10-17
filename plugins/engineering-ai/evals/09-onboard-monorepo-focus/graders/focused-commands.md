---
type: llm
---

PASS if the profile reports the commands of packages/web from packages/web/package.json (`vitest run` for tests, `eslint src` for lint, `tsc --noEmit` for typecheck), names pnpm as the package manager, and mentions running them from the root via the workspace tooling (e.g. `pnpm --filter @acme/web test` or `turbo run test --filter=@acme/web`) or notes the root `turbo run test` script.
FAIL if it reports jest (the api package's runner) as the web package's test command, reports only the root scripts without the package's own scripts, or claims any command was executed.

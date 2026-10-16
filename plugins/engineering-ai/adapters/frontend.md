# Adapter: frontend (React / TypeScript / JavaScript)

Use this to *discover* the repository's conventions. Do not assume any tool listed here is present — confirm it in config first.

## Signals that this is a frontend project
`package.json` depending on `react`, `react-dom`, `next`, `vite`, `@remix-run/*`, `vue`, `svelte`, `@angular/core`; folders like `src/components`, `app/`, `pages/`, `public/`.

## What to discover
| Topic | Where to look |
|---|---|
| Package manager | Lockfile (see standards/testing.md); `packageManager` field; workspaces in `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json` |
| Framework & build | `next.config.*`, `vite.config.*`, `webpack.config.*`, `remix.config.*`, `angular.json`; `scripts.build` |
| Language & strictness | `tsconfig*.json` (`strict`, `paths` aliases), `jsconfig.json` |
| Test runner | `jest.config.*` / `jest` key, `vitest.config.*` / `test` in vite config, `playwright.config.*`, `cypress.config.*`; `scripts.test*` |
| Lint/format | `eslint.config.*` / `.eslintrc*`, `biome.json`, `.prettierrc*`, `stylelint` config; `scripts.lint`, `scripts.format` |
| Typecheck | `scripts.typecheck` / `tsc --noEmit` in scripts or CI |
| Styling | Tailwind config, CSS modules (`*.module.css`), styled-components/emotion, design-system package |
| State & data | Redux/Zustand/Jotai/React Query/SWR/Apollo usage in existing code |
| Component conventions | File naming, co-located tests/stories (`*.test.tsx`, `*.stories.tsx`), default vs named exports, barrel files |
| i18n & a11y | i18n library and message files; existing a11y lint rules and testing-library queries |

## Common risk areas
SSR vs client-only code, hydration mismatches, hook dependency arrays, memoization changes that alter render behaviour, bundle size from new imports, accessibility regressions, feature flags, environment variables exposed to the client (`NEXT_PUBLIC_*`, `VITE_*` — never put secrets there).

## Verification hints
Prefer the repo's own scripts. For a monorepo, run checks for the affected workspace only (e.g. via the repo's filter syntax) when the repo documents how. E2E suites are usually slow and may need running services — ask before running them.

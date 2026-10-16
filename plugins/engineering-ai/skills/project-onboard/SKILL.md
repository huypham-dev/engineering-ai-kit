---
name: project-onboard
description: Inspect the current repository and report its stack, structure, existing AI/contributor instructions, and the real test, lint, typecheck and build commands found in config files, separating verified facts from assumptions. Use when starting work in an unfamiliar repo, or before planning or verifying a task when the verification commands are not yet known.
argument-hint: "[optional focus, e.g. a package path in a monorepo]"
disallowed-tools: Edit Write NotebookEdit
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Project onboarding (read-only)

Produce a factual profile of this repository so later stages pick the right conventions and commands. **Do not modify any file.** Do not install dependencies or run builds/tests in this skill — discovering a command is not the same as running it.

Focus (optional): $ARGUMENTS

## Procedure

1. **Git state.** Run `git status --short`, `git branch --show-current`, and `git log --oneline -5`. Note uncommitted changes; do not touch them.
2. **Existing instructions.** Read, if present: `CLAUDE.md` (root and nested), `.claude/settings.json` (not `settings.local.json` contents beyond what's needed), `AGENTS.md`, `.cursorrules`/`.cursor/rules`, `.github/copilot-instructions.md`, `CONTRIBUTING*`, `README*`, PR templates. These override generic conventions.
3. **Stack detection.** List top-level files and directories. Identify languages, frameworks, package managers and monorepo tooling from manifests and lockfiles. Then read the matching adapter(s) — only the ones that apply:
   - Frontend: `${CLAUDE_PLUGIN_ROOT}/adapters/frontend.md`
   - React Native: `${CLAUDE_PLUGIN_ROOT}/adapters/react-native.md`
   - Backend / other stacks: `${CLAUDE_PLUGIN_ROOT}/adapters/backend.md`
4. **Commands.** Follow the discovery rules in `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`. For each of *install, format, lint, typecheck, unit test, integration/E2E test, build*, record the exact command and the file+key it came from (e.g. `package.json → scripts.test`). Cross-check against CI config. If two sources disagree, report both.
5. **Conventions.** Sample 2–3 representative source files and their tests to note naming, folder layout, test location, import style, error handling and logging.
6. **Sensitive areas.** Note (without opening secret files — see `${CLAUDE_PLUGIN_ROOT}/standards/security.md`) where config/secrets live by name only, e.g. "`.env.example` lists DATABASE_URL, STRIPE_KEY".

## Output

```
## Project profile: <repo name>
Git: branch <x>; working tree <clean | N changed files: …>

### Stack (verified)
- <fact> — source: <file>

### Commands
| Purpose | Command | Source | Status |
|---|---|---|---|
| Lint | pnpm lint | package.json → scripts.lint; CI ci.yml | Verified (defined, not run) |
| Typecheck | — | — | Not found |

### Conventions observed
- …

### Existing instructions found
- …

### Assumptions (unverified)
- <assumption> — how to verify

### Missing information / questions
- …
```

Status values: **Verified (defined, not run)**, **Not found**, **Ambiguous** (explain). Never fill a cell with a command you did not find in the repository.

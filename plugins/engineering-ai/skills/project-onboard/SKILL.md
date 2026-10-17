---
name: project-onboard
description: Inspect the current repository and report its stack, structure, existing AI/contributor instructions, and the real test, lint, typecheck and build commands found in config files, separating verified facts from assumptions. Use when starting work in an unfamiliar repo, or before planning or verifying a task when the verification commands are not yet known.
argument-hint: "[optional focus path, e.g. packages/web in a monorepo]"
disallowed-tools: Edit Write NotebookEdit
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**) Bash(git status *) Bash(git branch --show-current) Bash(git log *) Bash(git rev-parse *)
---

# Project onboarding (read-only)

Produce a factual profile of this repository so later stages pick the right conventions and commands.

**Read-only means:** do not modify, create or delete files, and do not run commands that change the repository or its dependencies — no package installs (`npm/pnpm/yarn/bun install`, `pip install`, `bundle`, `go mod download`…), builds, tests, code generators, formatters, `git` writes, or `npx`/`init` commands. Discovering a command is not the same as running it. Allowed: read-only git commands, listing and reading files, searching.

Focus (optional): $ARGUMENTS

If a focus is given, it must be a path inside the repository (e.g. `packages/web`). If it does not exist or looks like ticket text rather than a path, ignore it and say so in the output.

## Procedure

1. **Git state.** Run `git rev-parse --is-inside-work-tree`, `git status --short`, `git branch --show-current` and `git log --oneline -5`. Handle these cases explicitly — never report them as a normal clean repo:
   - **Not a git repository** → report "Not a git repository". Warn that later stages cannot detect pre-existing changes or review a diff, and ask whether to run `git init` (do not run it).
   - **No commits yet** (`git log` fails with "does not have any commits yet") → report "No commits yet". Treat every file in `git status` as uncommitted work.
   - **Detached HEAD** (`git branch --show-current` prints nothing) → report "Detached HEAD at `<short sha>`" (`git rev-parse --short HEAD`). Warn that commits made here belong to no branch, and recommend creating a branch before implementation.
   - **Uncommitted or untracked changes** → list them. Do not touch them.
2. **Existing instructions.** Read, if present: `CLAUDE.md` and `CLAUDE.local.md` (root and nested), `.claude/CLAUDE.md`, `.claude/rules/*.md`, `AGENTS.md`, `.cursorrules` / `.cursor/rules/`, `.github/copilot-instructions.md`, `CONTRIBUTING*`, `README*`, PR templates. These override generic conventions. Do **not** read `.claude/settings.json` or `.claude/settings.local.json`: they can contain `env` blocks with real credentials.
3. **Stack detection.** List the files and directories at the repository root **and**, if a focus path is given, inside it. Identify languages, frameworks, package managers and monorepo tooling from manifests and lockfiles. Then read the matching adapter(s) — only the ones that apply:
   - Frontend: `${CLAUDE_PLUGIN_ROOT}/adapters/frontend.md`
   - React Native: `${CLAUDE_PLUGIN_ROOT}/adapters/react-native.md`
   - Backend / other stacks: `${CLAUDE_PLUGIN_ROOT}/adapters/backend.md`
4. **Commands.** Follow the discovery rules in `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`. With a focus path, look for the focused package's own manifest and scripts first (e.g. `packages/web/package.json`), then for how the repo runs them from the root (workspace filters such as `pnpm --filter`, `turbo run --filter`, `nx run`), and report both. For each of *install, format, lint, typecheck, unit test, integration/E2E test, build*, record the exact command, the file+key it came from (e.g. `package.json → scripts.test`) and its status (see the table below). Cross-check against CI config. If two sources disagree, report both.
5. **Conventions.** Sample 2–3 representative source files and their tests (inside the focus path, if given) to note naming, folder layout, test location, import style, error handling and logging.
6. **Sensitive areas.** Note (without opening secret files — see `${CLAUDE_PLUGIN_ROOT}/standards/security.md`) where config/secrets live by name only, e.g. "`.env.example` lists DATABASE_URL, STRIPE_KEY".

## Command status values

| Status | Use when |
|---|---|
| **Defined** | The command is defined in a script/target/task file (`package.json` scripts, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`, `noxfile.py`, …) or run verbatim in CI config. Not executed. |
| **Inferred** | Not defined anywhere, but it is the toolchain's standard command and the toolchain is confirmed by config — e.g. `go test ./...` from `go.mod`, `cargo test` from `Cargo.toml`. Name the file it was inferred from. |
| **Docs only** | Mentioned only in README/CONTRIBUTING/CLAUDE.md and not backed by a script, target or CI step. Say what is missing (e.g. "README says `make test`, but there is no Makefile"). |
| **Ambiguous** | Several candidates or conflicting sources. List them. |
| **Not found** | Nothing found. Leave the command cell as `—`. |

Never invent a command, and never give a command a stronger status than its source supports.

## Output

```
## Project profile: <repo name>  (focus: <path> | none)
Git: <branch <x> | Detached HEAD at <sha> | No commits yet | Not a git repository>; working tree <clean | N changed files: …>

### Stack (verified)
- <fact> — source: <file>

### Commands
| Purpose | Command | Source | Status |
|---|---|---|---|
| Lint | pnpm lint | package.json → scripts.lint; CI ci.yml | Defined |
| Unit test | go test ./... | go.mod (no Makefile or CI step) | Inferred |
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

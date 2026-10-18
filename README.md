# engineering-ai-kit

An internal Claude Code **plugin marketplace**. It ships one plugin, **`engineering-ai`**, a shared developer workflow for frontend (React/TypeScript/JavaScript), React Native and backend projects:

**Ticket → Explore → Plan → Human approval → Implement → Verify → Review → PR draft**

The plugin discovers each repository's own stack, scripts and conventions instead of assuming them. It stops for a developer decision whenever requirements are unclear, scope would grow, or checks fail. It never merges, pushes, or rewrites git history on its own.

## Quick start (developers)

```bash
# one-time: make sure git can read this repository without prompting (SSH key or `gh auth setup-git`)
claude plugin marketplace add huypham-dev/engineering-ai-kit
claude plugin install engineering-ai@engineering-ai-kit
```
Then, in any project:
```
/engineering-ai:ticket-to-pr <paste the ticket>
```
or run a single stage:

| Command | What it does |
|---|---|
| `/engineering-ai:project-onboard` | Profiles the repo: stack, real test/lint/typecheck/build commands, conventions. Read-only |
| `/engineering-ai:plan-task <ticket>` | Scoped plan with acceptance criteria, risks and verification, then asks for approval. Read-only |
| `/engineering-ai:implement-task` | Implements an **approved** plan within scope, runs checks with at most 2 fix attempts each |
| `/engineering-ai:review-changes [base]` | Reviews the real diff; findings marked Confirmed, Potential or Nit with `file:line`. Read-only |
| `/engineering-ai:prepare-pr` | PR title, description and checklist from real verification results. Text only |
| `/engineering-ai:ticket-to-pr <ticket>` | All of the above, with explicit approval checkpoints |
| `/engineering-ai:resolve-conflicts [base]` | Brings the branch up to date by **rebasing** (never merging), resolves conflicts hunk by hunk, stops on any conflict that needs a decision. Never force-pushes |

Full guides: [installation & updates](docs/installation.md) · [usage](docs/usage.md) · [workflow](docs/workflow.md) · [security model](docs/security-model.md)

## What's inside

```
.claude-plugin/marketplace.json        # marketplace catalog (name: engineering-ai-kit)
plugins/engineering-ai/                # the plugin
  .claude-plugin/plugin.json           # manifest and version
  skills/<name>/SKILL.md               # 5 stage skills, ticket-to-pr orchestrator, resolve-conflicts
  standards/                           # shared rules: coding, testing, code review, security, git
  adapters/                            # discovery guides: frontend, react-native, backend
  hooks/hooks.json, scripts/guard.sh   # PreToolUse guard (destructive git, PR merge, secret files)
tests/run.sh, tests/hook-cases.tsv     # deterministic tests (run in CI)
tests/fixtures/shop-cart.sh            # throwaway fixture repo for manual testing
docs/                                  # installation, usage, workflow, security, testing, distribution
```

### Design in one paragraph
Each skill has one job and points to shared **standards** rather than repeating them. Stack-specific knowledge lives in **adapters**, which only tell Claude *where to look* (lockfiles, configs, CI), never which tool to use. **Safety** is layered: skill-level controls (`disable-model-invocation` on the side-effecting skills, `disallowed-tools` on the read-only ones) plus one small `PreToolUse` hook. Everything else is advisory instruction, and [docs/security-model.md](docs/security-model.md) spells out which is which. The **workflow** loads each stage's instructions from the plugin directory and stops at explicit gates; it does not rely on skills calling each other.

## For maintainers
- [CONTRIBUTING.md](CONTRIBUTING.md): local development, adding a skill or guard rule, PR checklist
- [docs/testing.md](docs/testing.md): `tests/run.sh` and the manual procedure
- [docs/distribution.md](docs/distribution.md): marketplace hosting, versioning, release process
- [CHANGELOG.md](CHANGELOG.md)

> **Hosting note:** the intended home is a private company repository. This repository is currently `huypham-dev/engineering-ai-kit` (public). Update the add command in the docs when it moves.

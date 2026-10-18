# Contributing

## Ground rules
- **Small and reliable beats clever.** Each skill does one thing. Prefer Markdown instructions and native Claude Code features over custom code. Don't add dependencies.
- **Don't duplicate.** A rule that applies to several skills belongs in `plugins/engineering-ai/standards/`. Skills link to it with `${CLAUDE_PLUGIN_ROOT}/standards/<file>.md`.
- **Don't assume a stack.** Adapters describe *where to look*, not which tool to use. Never hard-code `npm`, `jest`, `pytest` and the like as *the* command.
- **Be honest about enforcement.** If a change relies on instructions rather than a hook or tool restriction, the docs must say so (`docs/security-model.md`).
- **Verify against the official docs** (https://code.claude.com/docs) before using any manifest field, frontmatter key, hook event or CLI flag. `claude plugin validate --strict` must pass.

## Local development
```bash
git clone <this repo> && cd engineering-ai-kit
claude --plugin-dir ./plugins/engineering-ai     # loads your working copy for this session
# edit files, then in the session:
/reload-plugins
```
Try changes on a throwaway fixture repo: `mkdir /tmp/x && cd /tmp/x && bash <repo>/tests/fixtures/shop-cart.sh`.

## Making changes
| Change | Also do |
|---|---|
| Edit a skill | Keep it under 500 lines; keep the frontmatter `name` equal to the directory name; update `docs/usage.md` if inputs or outputs change |
| Add a skill | Add it to `expected_skills` in `tests/run.sh`, document it in `docs/usage.md` and the README table |
| Change a standard or adapter | Check which skills reference it (`grep -r standards/<file> plugins/`) |
| Change the guard | Add rows to `tests/hook-cases.tsv` first, including look-alike commands that must *not* match. Keep it bash 3.2-compatible (macOS): POSIX character classes, no `\s`/`\b`. Update `docs/security-model.md` |
| Change workflow stop conditions | Update `docs/workflow.md` and the manual procedure in `docs/testing.md` |

## Before opening a PR
1. `tests/run.sh` passes (CI runs it too).
2. For skill or workflow behaviour changes, run the manual procedure (see `docs/testing.md`) and note the outcome in the PR. If you didn't run it, say so.
3. Add an entry under **Unreleased** in `CHANGELOG.md`.
4. Don't bump `version` in feature PRs; the release PR does that (see `docs/distribution.md`).

## Commit and PR conventions
Use [Conventional Commits](https://www.conventionalcommits.org): `feat(skills): …`, `fix(guard): …`, `docs: …`, `test: …`. One logical change per PR. Changes to the guard or the security docs need a second reviewer.

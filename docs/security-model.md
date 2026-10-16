# Security model: advisory vs enforced

The plugin combines **instructions**, which guide Claude, with a few **enforced controls**, which Claude Code applies whatever Claude decides. Neither is a security boundary on its own. Real protection comes from your permission settings, sandboxing, branch protection, code review and secret management.

## Enforced controls (Claude Code applies these)

| Control | Where | What it does | Limits |
|---|---|---|---|
| Guard hook | `hooks/hooks.json` → `scripts/guard.sh` (`PreToolUse` on Bash, Read, Edit, Write, NotebookEdit) | **Denies** force/delete pushes, `reset --hard/--merge/--keep`, `clean -f`, discarding `checkout`/`restore`, `branch -D`, `stash drop/clear`, `filter-branch`/`filter-repo`, `gh pr merge`. **Asks** before any other `git push`, `gh pr create`, `git rebase`, and before reading or editing likely secret files (`.env*` except examples, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, `id_rsa*`/`id_ed25519*`/`id_ecdsa*`, `credentials(.json)`, `.netrc`, `.pgpass`, `.envrc`) or Bash commands that name them | Pattern matching on the command text. It can over-match quoted text (e.g. a commit message containing `; git reset --hard`). It does **not** catch git aliases, scripts or Makefiles that run git, `bash -c "…"` strings, other languages' git bindings, MCP tools, or secret files with unusual names. If neither `jq` nor `python3` is installed it is inactive (with a visible warning). It runs on macOS/Linux; on native Windows it needs `bash` (Git Bash/WSL). Verified to block even in `bypassPermissions` mode (see testing.md) |
| `disable-model-invocation: true` | `implement-task`, `ticket-to-pr` | Claude cannot start implementation or the workflow on its own; you must type the command | Doesn't stop Claude from editing files in a normal conversation outside the plugin |
| `disallowed-tools: Edit Write NotebookEdit` | `project-onboard`, `plan-task`, `review-changes` | Removes the edit tools while the skill is active | Clears when you send your next message. Not applied when the workflow reads a stage file. Bash is still available (needed for git), so a Bash command could still write files |
| `allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)` | every skill | This *grants* rather than restricts: it pre-approves reading the plugin's own files (stage instructions, standards, adapters) so you don't get a permission prompt for each one | Covers only the plugin directory, and only during the turn in which the skill was invoked |

A hook that **denies** is final. A hook that **asks** shows you a permission prompt, and you decide. When a command is denied, the reason tells you to run it yourself if you really mean it.

## Advisory controls (instructions)
These are in `standards/*.md` and the skills. Claude follows them reliably in testing, but they are not guarantees:
- The plan approval gate and the other stop conditions in the workflow.
- Staying inside the approved scope; no new dependencies without approval.
- Never reading or printing secrets; never touching production.
- Honest verification reporting (PASSED / FAILED / NOT RUN / COULD NOT RUN).
- No push, PR creation or merge in the MVP.

## Recommended hardening for teams (outside this plugin)
- Use Claude Code permission **deny rules** in managed or project settings for anything that must never happen, e.g. `Bash(git push --force *)`, `Read(./.env)`, `Read(./**/*.pem)`. Deny rules and the hook complement each other.
- Keep secrets out of repositories entirely (secret manager, CI secrets). If a secret is in a working tree, assume an AI tool or a human may read it.
- Protect `main`/release branches on the git host: required reviews, no force pushes.
- Run untrusted or experimental work in a sandbox or container.
- Review the plugin source before rolling it out, and pin versions (see distribution.md).

## Reporting a problem
If the plugin does something unsafe, or the guard misses or wrongly blocks a command, open an issue in this repository with the command text (redact any secrets) and add a matching line to `tests/hook-cases.tsv` in the fix PR.

# Using the skills

All skills are namespaced under the plugin: type `/engineering-ai:` to list them. Four skills can also be triggered by Claude automatically when your request matches their description. `implement-task`, `ticket-to-pr` and `resolve-conflicts` only run when **you** type them.

| Skill | Invoke | Claude may trigger it? | Changes files? |
|---|---|---|---|
| project-onboard | `/engineering-ai:project-onboard [focus]` | Yes | No — Edit/Write removed while it runs; no installs/builds by instruction (Bash stays available) |
| plan-task | `/engineering-ai:plan-task <ticket>` | Yes | No (Edit/Write removed while it runs) |
| implement-task | `/engineering-ai:implement-task [notes]` | **No** | Yes, approved scope only |
| review-changes | `/engineering-ai:review-changes [base\|--staged]` | Yes | No (Edit/Write removed while it runs) |
| prepare-pr | `/engineering-ai:prepare-pr [base] [ticket]` | Yes | No (text output only) |
| ticket-to-pr | `/engineering-ai:ticket-to-pr <ticket>` | **No** | Only in stage 4, after approval |
| resolve-conflicts | `/engineering-ai:resolve-conflicts [base]` | **No** | Yes, after approval: rebases and edits conflicted files |

## project-onboard
Run it first in an unfamiliar repository.
```
/engineering-ai:project-onboard
/engineering-ai:project-onboard packages/web      # focus on one workspace of a monorepo
```
**Input:** optional focus path inside the repo (e.g. a monorepo package). **Output:** a project profile: git state (including non-git, no-commit and detached-HEAD cases), stack (verified, with sources), a command table with status `Defined`, `Inferred`, `Docs only`, `Ambiguous` or `Not found`, conventions, existing instructions, assumptions and open questions.

## plan-task
```
/engineering-ai:plan-task SHOP-101: add removeItem(cart, sku); unknown sku is a no-op
/engineering-ai:plan-task @tickets/SHOP-101.md
```
**Input:** ticket text, an ID plus a description, or a file. (The plugin doesn't connect to Jira/Linear; paste the ticket content.) **Output:** a plan with status `READY FOR APPROVAL` or `DRAFT — BLOCKED ON QUESTIONS`, acceptance criteria, files in scope, out-of-scope items, risks, a verification strategy, and a closing approval request.

## implement-task
Run it after you approve a plan in the same conversation.
```
/engineering-ai:implement-task
/engineering-ai:implement-task use the existing money helpers, not a new util
```
**Input:** an approved plan in the conversation. If there is none, it asks. **Output:** an implementation report with status `COMPLETE` or `STOPPED — <reason>`, the changed files, any deviations from the plan, a verification table with real results, the attempts made, and follow-ups.

Your normal permission prompts still apply to edits and commands. Answering them is how you authorize running checks.

## review-changes
```
/engineering-ai:review-changes            # uncommitted changes (or branch vs upstream if clean)
/engineering-ai:review-changes main       # current branch vs main, plus uncommitted
/engineering-ai:review-changes --staged
```
**Output:** a verdict; Confirmed findings (`file:line`, a concrete failure scenario, a suggested fix); Potential findings (with what would confirm them); test gaps; a scope check against the plan; nits; and what was checked.

## prepare-pr
```
/engineering-ai:prepare-pr
/engineering-ai:prepare-pr develop SHOP-101
```
**Output:** readiness (`READY FOR REVIEW` or `NOT READY`), a title in the repo's convention, a description that follows the repo's PR template if it has one, a verification table with only results that actually ran, risks, limitations, a reviewer checklist, and the push/PR commands **for you to run**.

## ticket-to-pr
```
/engineering-ai:ticket-to-pr SHOP-101: add removeItem(cart, sku) …
```
See [workflow.md](workflow.md).

## resolve-conflicts
Run it on your feature branch when it has fallen behind its base branch or has conflicts with it.
```
/engineering-ai:resolve-conflicts                 # base = upstream default branch (origin/HEAD, origin/main, origin/master)
/engineering-ai:resolve-conflicts origin/develop
```
It **always rebases** and never runs `git merge` or `git pull`. If you already started a rebase and it stopped on a conflict, run the skill and it picks up from there.

1. **Plan (read-only):** commits to replay, commits the base gained, predicted conflicts (`git merge-tree`), lockfiles to regenerate, a backup branch `backup/<branch>-pre-rebase`, whether a force-push will be needed, and the verification commands. Then it asks for approval.
2. **After "approve":** creates the backup, runs `git rebase <base>`, and resolves each stopped commit with Edit, keeping both sides' intent. Lockfiles are regenerated with the repo's own command, never hand-edited. Each `git rebase` / `--continue` triggers a guard confirmation prompt.
3. **Stops for you** when both sides change the same logic or the same config value, on binary, both-added or submodule conflicts, on a deleted file that wasn't simply renamed, or when a check fails because of a resolution. Imports, tests, fields, lists and renamed files are combined by the patterns in `references/patterns.md`, and a choice you made once is reused for similar conflicts later in the rebase. It shows the ancestor, base and branch versions with 2–3 options and a recommendation. It never runs `--skip` or `--abort` unless you say so.
4. **Output:** a rebase report (commits replayed, a conflict table, verification results) and the commands **for you to run**: `git push --force-with-lease` if the branch was pushed before, and `git branch -D backup/<branch>-pre-rebase` when you are happy.

Remember that during a rebase "ours" is the base branch and "theirs" is your commit. The skill explains conflicts in terms of *base* and *branch* to avoid that trap.

## Tips
- Start a fresh session per ticket, so earlier plans and approvals don't carry over by accident.
- Put team-specific commands and rules in the project's own `CLAUDE.md`. The skills read it and it takes precedence over the plugin's generic standards.
- If the plugin picks the wrong command, fix the repo's docs or scripts, not the plugin. The plugin discovers commands; it doesn't hard-code them.

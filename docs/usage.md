# Using the skills

All skills are namespaced under the plugin: type `/engineering-ai:` to list them. Three skills can also be triggered by Claude automatically when your request matches their description. `implement-task` and `ticket-to-pr` only run when **you** type them.

| Skill | Invoke | Claude may trigger it? | Changes files? |
|---|---|---|---|
| project-onboard | `/engineering-ai:project-onboard [focus]` | Yes | No (Edit/Write removed while it runs) |
| plan-task | `/engineering-ai:plan-task <ticket>` | Yes | No (Edit/Write removed while it runs) |
| implement-task | `/engineering-ai:implement-task [notes]` | **No** | Yes, approved scope only |
| review-changes | `/engineering-ai:review-changes [base\|--staged]` | Yes | No (Edit/Write removed while it runs) |
| prepare-pr | `/engineering-ai:prepare-pr [base] [ticket]` | Yes | No (text output only) |
| ticket-to-pr | `/engineering-ai:ticket-to-pr <ticket>` | **No** | Only in stage 4, after approval |

## project-onboard
Run it first in an unfamiliar repository.
```
/engineering-ai:project-onboard
/engineering-ai:project-onboard packages/web      # focus on one workspace of a monorepo
```
**Input:** optional focus path. **Output:** a project profile: stack (verified, with sources), a command table (`Verified (defined, not run)`, `Not found` or `Ambiguous`), conventions, existing instructions, assumptions and open questions.

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

## Tips
- Start a fresh session per ticket, so earlier plans and approvals don't carry over by accident.
- Put team-specific commands and rules in the project's own `CLAUDE.md`. The skills read it and it takes precedence over the plugin's generic standards.
- If the plugin picks the wrong command, fix the repo's docs or scripts, not the plugin. The plugin discovers commands; it doesn't hard-code them.

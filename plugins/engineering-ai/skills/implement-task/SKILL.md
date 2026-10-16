---
name: implement-task
description: Implement a plan that the developer has explicitly approved, following repository conventions, staying inside the approved scope, and running the discovered verification checks with bounded retries. Stops and reports on scope changes or repeated failures.
argument-hint: "[optional: reference to the approved plan, or extra instructions]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Implement an approved plan

Extra instructions: $ARGUMENTS

## Preconditions — check all, stop if any fails
1. An **approved plan** exists in this conversation (from `plan-task` or equivalent), and the developer explicitly approved it ("approve", "approved", "go ahead", "LGTM, implement"). A plan shown but not approved is not approved. If unsure, ask: "Do you approve the plan above as written?" and stop.
2. The plan status is not BLOCKED ON QUESTIONS.
3. Run `git branch --show-current`. If the approved plan proposes a new branch, create it with `git switch -c <name>` (approved as part of the plan). If you are on a default/protected branch and the plan says nothing about branches, ask before editing.
4. Run `git status --short`. If there are uncommitted changes that were not made by this workflow, list them and ask before editing any of those files (`${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`).

## Rules
Follow `${CLAUDE_PLUGIN_ROOT}/standards/coding.md`, `${CLAUDE_PLUGIN_ROOT}/standards/security.md` and `${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`. In particular:
- Edit only files in the approved scope. Do not refactor, rename or reformat unrelated code.
- No new dependencies, public contract changes, or config/CI changes unless the plan lists them.
- Do not commit, push, or create branches unless the developer asks.

## Procedure
1. For a bugfix: first add or run the test that reproduces the bug and confirm it **fails for the expected reason**. Record the command and output.
2. Make the changes, file by file, following existing patterns.
3. Add or update tests as the plan specifies.
4. Run verification per `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`: narrowest relevant checks first, using only commands discovered in the repo. If the developer has not authorized running commands and your permissions prompt for them, that prompt *is* the authorization step — do not try to bypass it.
5. On failure: diagnose, fix, re-run — **max 2 fix attempts per failing check**. Never weaken tests to pass.

## Stop conditions — stop and report, do not continue
- **Scope change:** the correct fix needs a file, module, dependency, schema or API outside the approved plan. Explain what and why, propose a plan amendment, and wait for approval.
- **Requirement change:** you discover the plan's assumptions are wrong.
- **Repeated failure:** a check still fails after 2 attempts.
- **Cannot verify:** a required check cannot run (missing tool, service, network). Report COULD NOT RUN; do not claim success.
- **Pre-existing failure:** a check fails the same way without your change. Report it; do not fix it unless approved.

## Output
```
## Implementation report   Status: COMPLETE | STOPPED — <reason>
Changes:
- path — summary
Deviations from plan: none | …
Verification:
| Check | Command | Result | Evidence |
|---|---|---|---|
| Unit tests | `pnpm test src/foo` | PASSED | 42 passed, 0 failed |
| Typecheck | `pnpm typecheck` | FAILED | src/a.ts:12 TS2345 … |
| E2E | — | NOT RUN | needs running backend |
Attempts: <check>: 2 attempts, still failing — hypothesis: …
Follow-ups noticed (not done): …
Next step: review with /engineering-ai:review-changes
```

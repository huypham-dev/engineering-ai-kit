# Ticket-to-PR workflow

`/engineering-ai:ticket-to-pr <ticket>` coordinates the five stage skills. You can also run each stage on its own (see [usage.md](usage.md)).

```
 Ticket
   │
   ▼
 1 Onboard ──────────── read-only: stack, commands, git state
   │
   ▼
 2 Plan ─────────────── read-only: criteria, scope, risks, verification
   │   └─ blocking questions? ──► STOP (NEEDS_INPUT) ──► you answer ──► back to 2
   ▼
 3 APPROVAL GATE ────── STOP. Waits for an explicit "approve"
   │   └─ plan edits? ──► revise plan ──► ask again
   ▼
 4 Implement + verify ─ approved scope only; ≤2 fix attempts per failing check
   │   ├─ scope change needed? ──► STOP (NEEDS_INPUT) ──► new approval gate
   │   └─ still failing / can't run? ──► STOP (BLOCKED) with evidence
   ▼
 5 Review ───────────── read-only: Confirmed / Potential / Nit
   │   └─ Confirmed high/medium? ──► STOP (NEEDS_INPUT): fix them?
   ▼
 6 PR draft ─────────── text only: title, description, checklist
   │
   ▼
 Final summary (always, including after an early stop)
```

## How the stages are run
Claude Code has no native "skill calls skill" mechanism. Instead, the orchestrator has Claude **Read every stage's `SKILL.md` and the shared standards from the plugin directory in its first turn** ("stage 0"), then follow each one when its stage comes. That approach is deterministic, and it also works for `implement-task`, which Claude cannot invoke on its own (`disable-model-invocation: true`).

Why load everything up front: the plugin files sit outside your project, so reading them normally needs permission. Each skill pre-approves `Read` on the plugin directory with `allowed-tools`, but that grant only lasts for the turn in which the skill was invoked. In testing, a stage file read in a later turn (after you reply "approve") was refused in headless mode, and an interactive session would have prompted for it. Loading in stage 0 avoids both.

Trade-off: when a stage is read as a file, its frontmatter is not applied. So the `disallowed-tools` restriction that removes Edit/Write from the read-only skills only takes effect when you run those skills directly. Inside the workflow, read-only behaviour comes from the orchestrator's hard rules (instructions, not enforcement).

## Checkpoints
| Checkpoint | Trigger | What you do |
|---|---|---|
| Clarification | Plan has blocking questions | Answer them; planning resumes |
| Uncommitted work | Stage 1 found changes not made by the workflow | Say whether to proceed and which files are off-limits |
| **Plan approval** | Always, after stage 2 | Reply "approve" to the plan as written, or request edits |
| Scope amendment | Implementation needs a file, dependency or contract outside the plan | Approve or reject the amendment |
| Verification blocked | A check still fails after 2 attempts, or cannot run | Decide: fix the environment, change the plan, or accept with a known limitation |
| Review findings | Confirmed high/medium issues | Approve a listed set of fixes, or accept the risk |

**What counts as approval:** an explicit affirmative reply to the plan just shown. Silence, an unrelated question, or "looks interesting" is not approval.

## Stage results
Each stage ends with `Stage <n> result: PASS | NEEDS_INPUT | BLOCKED — <reason>`. Only PASS moves on automatically, and the workflow never skips a stage.

## What the workflow never does
Push, open a remote PR, merge, rewrite history, discard changes, install new dependencies without approval, touch production systems, or claim that a check passed when it did not run. The guard hook enforces part of this list (see [security-model.md](security-model.md)).

## Example session (abridged)
```
> /engineering-ai:ticket-to-pr SHOP-101: add removeItem(cart, sku); unknown sku is a no-op; unit tested

## Project profile … Commands: Unit test `npm test` (package.json → scripts.test) …
Stage 1 result: PASS
## Plan: removeItem   Status: READY FOR APPROVAL
Scope: src/cart.js, test/cart.test.js … Verification: npm test …
> Approval needed: reply "approve" to implement this plan as written …
Stage 2 result: PASS

> approve

## Implementation report  Status: COMPLETE
| Unit tests | npm test | PASSED | 4 passed, 0 failed |
Stage 4 result: PASS
## Review … Verdict: no confirmed issues
Stage 5 result: PASS
## PR draft  Readiness: READY FOR REVIEW …
## Ticket-to-PR summary …
```

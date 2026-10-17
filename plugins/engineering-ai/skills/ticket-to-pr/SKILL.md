---
name: ticket-to-pr
description: Run the full ticket-to-PR workflow — explore, plan, human approval, implement, verify, review, PR draft — with explicit stop points for approval, ambiguity, scope changes and failed checks.
argument-hint: "<ticket text, ticket ID, or path to a ticket file>"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Ticket → PR workflow

Ticket: $ARGUMENTS

You coordinate six stages. Each stage's full instructions live in its own skill file. Referring to a stage by name does not run it — you run a stage by following its instructions file exactly, including its output format.

## Stage 0 — load all instructions now
Before stage 1, in this first turn, use the Read tool on **all** of these files (permission to read them is pre-approved only during this turn):
- the five stage files in the table below, and
- `${CLAUDE_PLUGIN_ROOT}/standards/coding.md`, `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`, `${CLAUDE_PLUGIN_ROOT}/standards/code-review.md`, `${CLAUDE_PLUGIN_ROOT}/standards/security.md`, `${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`.

In later turns (after the developer replies), use the content you already loaded; do not re-read these files. If a read is refused, stop with `Stage 0 result: BLOCKED` and say which file — never improvise a stage without its instructions.

| # | Stage | Instructions file | Modifies files? |
|---|---|---|---|
| 1 | Onboard | `${CLAUDE_PLUGIN_ROOT}/skills/project-onboard/SKILL.md` | No |
| 2 | Plan | `${CLAUDE_PLUGIN_ROOT}/skills/plan-task/SKILL.md` | No |
| 3 | **Approval gate** | (this file) | No |
| 4 | Implement + verify | `${CLAUDE_PLUGIN_ROOT}/skills/implement-task/SKILL.md` | Yes, approved scope only |
| 5 | Review | `${CLAUDE_PLUGIN_ROOT}/skills/review-changes/SKILL.md` | No |
| 6 | PR draft | `${CLAUDE_PLUGIN_ROOT}/skills/prepare-pr/SKILL.md` | No |

When a stage file says `$ARGUMENTS`, substitute: stage 1 (onboard) — a focus path only if the ticket names one package/directory of a monorepo, otherwise nothing (never the ticket text); stage 2 (plan) — the ticket; later stages — the relevant context. Ignore its frontmatter; the rules below apply instead.

## Stage results
End every stage with one line: `Stage <n> result: PASS | NEEDS_INPUT | BLOCKED — <reason>`.
- **PASS** → continue to the next stage in the same turn, unless the next stage is a gate.
- **NEEDS_INPUT** or **BLOCKED** → stop the workflow, report, and wait for the developer. Never silently skip a stage or continue past a failure.

## Hard rules
1. **Stages 1–3 are read-only.** Do not edit files before approval at stage 3.
2. **Approval gate (stage 3).** After the plan, stop and ask for approval using the plan's approval line. Only an explicit affirmative reply to *this* plan counts ("approve", "approved", "yes, implement it"). Edits to the plan → revise it, show the revised plan, ask again. Anything else → answer it and ask again. Never assume approval.
3. **Blocking questions** from stage 2 → stop with NEEDS_INPUT. Resume at stage 2 after answers.
4. **Pre-existing uncommitted changes** found in stage 1 → before stage 4, ask the developer whether to proceed with them in place (and which files are off-limits).
5. **Scope changes during stage 4** → stop with NEEDS_INPUT, show the proposed plan amendment, and treat it as a new approval gate.
6. **Verification failures** → the implement stage allows at most 2 fix attempts per failing check; after that the stage result is BLOCKED. A check that could not run is reported as COULD NOT RUN — it is not a pass.
7. **Review findings (stage 5)** → if there are Confirmed high/medium findings, stop with NEEDS_INPUT and ask whether to fix them (fixes are a small new approval: list exactly what you'd change). Potential findings are reported, not acted on.
8. **Stage 6 gate** → ask before drafting the PR only if stage 4 or 5 ended with anything but PASS; otherwise draft it. The draft is text only.
9. **No remote or destructive git operations** at any stage: no push, no PR creation, no merge, no history rewrite, no discarding changes (`${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`).

## Final summary (always, including when stopped early)
```
## Ticket-to-PR summary
Stages: 1 ✅ 2 ✅ 3 ✅ approved 4 ⚠️ BLOCKED 5 — 6 —
Changed files: …
Verification evidence: <table from implement/review, real results only>
Unresolved issues: …
Next steps for the developer: …
```

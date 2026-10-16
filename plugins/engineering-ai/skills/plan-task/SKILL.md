---
name: plan-task
description: Analyze a ticket, bug report or feature request against the current repository and produce a scoped implementation plan with acceptance criteria, affected files, risks, edge cases and a verification strategy, then ask for explicit approval. Read-only; asks clarifying questions when requirements are ambiguous. Use before implementing any non-trivial change.
argument-hint: "<ticket text, ticket ID, or path to a ticket file>"
disallowed-tools: Edit Write NotebookEdit
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Plan a task (read-only)

Turn a request into a plan a developer can approve. **Do not modify source files, create branches, install packages or run commands with side effects.**

Ticket / request: $ARGUMENTS

If no ticket was given, ask for it and stop.

## Procedure

1. **Repository context.** If a project profile from `project-onboard` is not already in this conversation, gather the minimum yourself: git status, stack, and the real verification commands (rules in `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`).
2. **Understand the request.** Restate the goal in one or two sentences. Extract explicit acceptance criteria; derive implicit ones and mark them *(derived)*.
3. **Explore.** Find the code involved: entry points, callers, tests, types/contracts, config. Read before concluding. Note existing patterns the change should follow (`${CLAUDE_PLUGIN_ROOT}/standards/coding.md`).
4. **Ambiguity check.** List open questions. A question is **blocking** if different answers lead to materially different code, behaviour, data or API contracts. Examples: undefined expected behaviour for an error case, conflicting requirements, unknown target platform, unclear whether a public contract may change.
   - If there are blocking questions: output the questions (numbered, each with the options you see and your recommendation), mark the plan **DRAFT — BLOCKED ON QUESTIONS**, and stop. Do not guess.
5. **Risk assessment.** Rate overall risk low / medium / high. High includes: auth, payments, PII, data migrations or deletion, public API/schema changes, concurrency, build/release config, new dependencies (see `${CLAUDE_PLUGIN_ROOT}/standards/security.md`).
6. **Plan.** Smallest change that meets the criteria. List each file to change or create and why. Anything not listed is out of scope.
7. **Verification strategy.** Which tests to add or update, and which discovered commands to run. For a bugfix, include a step that reproduces the bug with a failing test first. Name checks that cannot run here and why.

## Output

```
## Plan: <short title>   Status: READY FOR APPROVAL | DRAFT — BLOCKED ON QUESTIONS
Goal: …
Acceptance criteria:
1. … 
2. … (derived)
Scope — files to change:
- path/to/file.ts — what and why
Out of scope (explicitly not changing): …
Branch: current <name>; proposed: <keep current | create `<branch-name>` before implementing>
New dependencies: none | <name, reason>  ← requires approval
Risks & edge cases: …   Overall risk: low|medium|high
Verification:
- Add/modify test: …
- Run: `<command>` (source: …)
- Cannot run here: … (reason)
Assumptions: …
Open questions: … (blocking / non-blocking)
```

End with exactly this line when status is READY FOR APPROVAL:

> **Approval needed:** reply "approve" to implement this plan as written, or tell me what to change. I will not modify files until you approve.

A plan is never approved by default, by silence, or by the developer asking an unrelated question.

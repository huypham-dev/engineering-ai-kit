---
name: review-changes
description: Review the actual git diff (working tree, staged, or a branch vs its base) for bugs, regressions, security risks, missing edge cases and test gaps, reporting each finding with file:line and classifying it as Confirmed, Potential or Nit. Read-only; never edits files. Use after implementing a change or before opening a PR.
argument-hint: "[base ref, e.g. main | --staged | path filter]"
disallowed-tools: Edit Write NotebookEdit
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Review changes (read-only)

**This is a review-only invocation: do not modify, create, stage or delete files**, even to fix an obvious issue. Report it instead.

Target: $ARGUMENTS

## 1. Determine the diff
- `--staged` → `git diff --staged`
- A ref (e.g. `main`, `origin/main`) → `git diff <ref>...HEAD` plus uncommitted changes (`git diff HEAD`)
- Nothing given → uncommitted changes (`git diff HEAD` and untracked files from `git status --short`); if the working tree is clean, compare the current branch to its upstream/default branch and say which base you used.
- If the diff is empty, say so and stop.

Start with `git diff --stat` to see size. Read every changed hunk. Skip generated files and lockfiles except to note unexpected changes in them.

## 2. Review
Apply `${CLAUDE_PLUGIN_ROOT}/standards/code-review.md` and the security checklist in `${CLAUDE_PLUGIN_ROOT}/standards/security.md`. For each suspicious hunk, read the surrounding code, callers and tests before deciding. If an approved plan exists in the conversation, also check the diff against it: missing acceptance criteria, and changes outside the approved scope.

You may run read-only commands (e.g. `git log`, `git blame`, grep) and, if the developer allows, existing tests to confirm a suspected bug. Do not run commands that modify files.

## 3. Output
```
## Review: <base>…<head or working tree>  (<N files, +A/−D>)
Verdict: no confirmed issues | changes requested | blocking issues

### Confirmed
[Confirmed] high — src/cart.ts:48
What: …
Why it matters: <concrete input/state → wrong result>
Suggested fix: …

### Potential (needs verification)
[Potential] medium — src/api.ts:12
What: …
To confirm: <what to check>

### Test gaps
- …

### Scope check (if a plan exists)
- Out-of-plan changes: none | …
- Acceptance criteria not covered: none | …

### Nits (optional)
- …

Checked: <what you examined, e.g. all 6 files, callers of X, ran `pnpm test cart`: PASSED>
```

Never label speculation as Confirmed. Style preferences that no documented repo rule backs are Nits at most.

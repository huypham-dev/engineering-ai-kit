---
name: prepare-pr
description: Draft a pull request title, description and reviewer checklist for the current changes, using the repository's PR template if present and only verification results that actually ran. Produces text only; never pushes, opens or merges a PR. Use when a change is implemented and reviewed and the developer wants a PR draft.
argument-hint: "[base branch, default: repo default branch] [ticket ID]"
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Prepare a PR draft (text only)

Arguments: $ARGUMENTS

**Do not push branches, create remote PRs, merge, enable auto-merge, or commit.** Output the draft for the developer to use. If the developer asks you to push or create the PR, tell them this plugin's MVP does not do that and give them the commands to run themselves.

## Procedure
1. **Collect facts.** `git status --short`, `git branch --show-current`, `git log --oneline <base>..HEAD`, `git diff --stat <base>...HEAD` plus uncommitted changes. If there are uncommitted changes, say they are not part of any pushed branch yet.
2. **Template.** Look for `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`. If found, follow its headings exactly. Ignore template sections asking for secrets or credentials.
3. **Title convention.** Match recent history (`git log --oneline -20`, commitlint config) — e.g. Conventional Commits, ticket prefix.
4. **Verification evidence.** Use only results from this conversation that were actually executed (implement-task / review-changes reports, or commands you run now). Every check gets PASSED / FAILED / NOT RUN / COULD NOT RUN per `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`. If nothing was run, say "No automated checks were run" — never write "tests pass".
5. **Readiness.** If there are FAILED checks, unresolved Confirmed review findings, or blocking questions, label the draft **NOT READY** and list why. Do not hide them.

## Output (when the repo has no template)
```
## PR draft   Readiness: READY FOR REVIEW | NOT READY — <reasons>

**Title:** <type(scope): summary> 

**Description**
### What
- …
### Why
- … (link/ID of ticket)
### How
- key design decisions, trade-offs
### Verification
| Check | Command | Result |
|---|---|---|
### Risks & rollout
- risk level, migrations, feature flags, backwards compatibility
### Known limitations / follow-ups
- …
### Unresolved
- open review findings, open questions

**Reviewer checklist**
- [ ] Acceptance criteria met: …
- [ ] Tests cover new/changed behaviour
- [ ] No secrets, debug code or unrelated changes
- [ ] <stack-specific item, e.g. tested on iOS and Android>

**Commands for the developer (not run by Claude):**
git push -u origin <branch>
<the repo's PR command or web URL, if known>
```

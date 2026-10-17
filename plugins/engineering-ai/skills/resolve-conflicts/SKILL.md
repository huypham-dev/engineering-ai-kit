---
name: resolve-conflicts
description: Bring the current feature branch up to date with its base branch by rebasing (never merging), resolving conflicts commit by commit while preserving the intent of both sides, then verifying with the repository's own checks. Plans first and waits for approval; stops for a developer decision on any conflict that needs judgement. Never force-pushes.
argument-hint: "[base ref, e.g. origin/main — defaults to the upstream default branch]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Resolve conflicts by rebasing onto the base branch

Base: $ARGUMENTS

This skill always uses `git rebase`. It never runs `git merge` or `git pull` (which merges by default) to sync with the base. In this first turn, Read `${CLAUDE_PLUGIN_ROOT}/skills/resolve-conflicts/references/patterns.md`, `${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`, `${CLAUDE_PLUGIN_ROOT}/standards/testing.md` and `${CLAUDE_PLUGIN_ROOT}/standards/coding.md`. Reading them is pre-approved only during this turn, and resolving happens in a later turn.

## Rebase vocabulary
The sides are **inverted** compared to a merge: `HEAD` / "ours" / `<<<<<<< HEAD` / stage `:2:` is the **base** plus the commits already replayed; "theirs" / `>>>>>>> <sha>` / stage `:3:` is **the developer's commit being replayed**; `:1:` is the common ancestor. Read a side with `git show :<n>:<path>`.

## Hard rules
- Never: `git merge`, `git pull`, any `git push` (give the developer the command), `git reset --hard`, `git checkout --ours/--theirs`, `git restore` of files, `git rebase -i`, `-X ours/theirs`, `-s ours`, `--no-verify`, changing git config.
- Resolve with the Edit tool, hunk by hunk. Never replace a whole file with one side or write through shell redirection.
- Keep the intent of **both** sides, or stop for a decision. Never silently drop a change.
- Invent nothing: the result holds only what one side or the other has, plus the minimum glue to combine them.
- Touch only conflicted files and regenerated lockfiles or generated files. No refactoring or reformatting.
- No `git rebase --skip` or `--abort` without the developer's go-ahead.
- Continue with `git -c core.editor=true rebase --continue` (no `GIT_EDITOR=…` prefix).

## 1. Inspect (read-only)
1. `git status`, `git branch --show-current`, `git log --oneline -5`.
2. **Rebase already in progress** (the developer started it): read `head-name`, `onto` and `orig-head` from `$(git rev-parse --git-path rebase-merge)` (or `rebase-apply`). Use `onto` as `<base>`; if a given or default base doesn't resolve to it, ask which is meant. Report a short plan (commit being replayed, conflicted files, your 4a analysis, backup at `orig-head`, regeneration and verification commands). The developer's confirmation is the approved plan: create the backup, then go to step 4.
   **Merge in progress:** say this skill rebases, and ask whether they want to run `git merge --abort` themselves.
3. Stop and ask if the tree has uncommitted or untracked changes (never stash, commit or discard them yourself; offer committing, or an approved `git stash push -u` and later `git stash pop`), or if the branch is the default/protected branch.
4. Base: the argument, else `origin/HEAD`, else `origin/main` / `origin/master`. Say why. Propose `git fetch origin <base-branch>` if the ref may be stale; fetch only after approval.
5. Facts for the plan:
   - `git log --oneline --reverse <base>..HEAD` (to replay) and `git log --oneline HEAD..<base>` (base gained). Either empty → report and stop.
   - Predicted conflicts: `git merge-tree --write-tree --name-only --no-messages <base> HEAD` (git ≥ 2.38; exit 1 = conflicts, paths after the first line). It compares final tips only, so intermediate commits may still conflict.
   - Shared branch: an upstream (`git rev-parse --abbrev-ref @{u}`) means a force-push afterwards; other authors (`git log --format='%an' <base>..HEAD | sort -u`) → recommend against and ask.
   - Lockfiles or generated files among the conflicts, with the repo's own regeneration command (never invented).
   - Backup: `backup/<branch>-pre-rebase`, or with a `-<YYYYMMDD>` suffix if that branch exists. Never reuse or overwrite an old one.

## 2. Plan and wait for approval
```
## Rebase plan: <branch> onto <base>   Status: READY FOR APPROVAL | BLOCKED — <reason>
Base: <ref> (<why>)  · fetch first: yes (`git fetch origin <base-branch>`) | no
Commits to replay (<n>): <sha> <subject> …
Base has gained (<m>): <sha> <subject> …
Predicted conflicts: <paths> | none | not predicted (final tips only)
Lockfiles / generated files: <path> → `<command>` (<source>) | none
Backup: `git branch <backup>`
Pushed already: no | yes → YOU run `git push --force-with-lease` afterwards
Other authors on the branch: none | <names>
Verification: <discovered commands> | Not found
```
End with: **Approval needed:** reply "approve" to create the backup branch, rebase onto `<base>`, resolve mechanical conflicts, stage resolved files and continue. I will stop on any conflict that needs a decision.

Change nothing in the repository before an explicit approval.

## 3. Start (after approval)
Fetch if planned, create the backup, run `git rebase <base>` (the guard's confirmation prompt is expected). No conflicts → step 5.

## 4. Resolve, one stopped commit at a time
a. **Read both sides and why they exist.** `git show REBASE_HEAD` and `git log -1 --format=%B REBASE_HEAD` for the branch; `git log --format='%h %s%n%b' <merge-base>..<base> -- <path>` for the base (`<merge-base>` = `git merge-base ORIG_HEAD <base>`). Read PRs or issues the messages reference with read-only `gh pr view` / `gh issue view`, or say they weren't read. Conflicted paths: `git diff --name-only --diff-filter=U`. Don't use `git rebase --show-current-patch` (the guard asks to confirm it).
b. **Classify each conflict** using `references/patterns.md`: *mechanical* (independent changes, combined by its patterns) or *needs a decision* → stop. If the developer already decided a similar conflict, apply the same choice and say so; ask again when it differs.
c. **Lockfiles and generated files:** resolve their sources first, then regenerate with the planned command. Never hand-edit them. Installing or upgrading beyond what both sides declare needs approval.
d. **Check before continuing:** no markers (`git diff --check`, search for `<<<<<<<`, `=======`, `>>>>>>>`), then the narrowest discovered checks covering the resolved files. A failure your resolution caused: fix it, max 2 attempts, then stop. A failure you can't attribute: report the evidence and ask.
e. `git add <resolved paths>`, then continue. Before continuing, give one line per file: how it was resolved and the source of each side's intent; name anything dropped (only after a decision) and why.
f. Commit became empty because the base already has it: show the evidence and ask before `--skip`.

## 5. Verify
1. `git status` shows no rebase in progress; `git log --oneline <base>..HEAD` lists the replayed commits.
2. `git diff <backup> HEAD --stat` shows only the base's changes plus your resolutions; explain anything else.
3. Run the verification commands per `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`; report PASSED / FAILED / NOT RUN / COULD NOT RUN. A failure that also happens on the base is pre-existing; one caused by a resolution → stop with options. Never rewrite history to fix it.

## Stop conditions — stop, leave the rebase as it is
- A conflict needs a decision: show the ancestor, base and branch versions, each side's intent quoted from its commit, PR or issue, and 2–3 resolutions with trade-offs and a recommendation.
- The cases `references/patterns.md` marks as stop (binary, delete/modify without a clear rename, both-added, submodule, conflicting config values), or a lockfile that can't be regenerated.
- A verification failure caused by a resolution, or anything outside the approved plan.

Each stop says how to resume (reply with a decision) and undo (`git rebase --abort` while in progress, `<backup>` afterwards). Run either only on request.

## Output
```
## Rebase report   Status: COMPLETE | STOPPED — <reason> | ABORTED (on request)
Branch: <branch>  onto <base> @ <sha>   Backup: <backup>
Commits replayed: <n>/<total>   Skipped (approved): none | <sha subject — why>
Dropped (approved): none | <what, from which side — why>
Conflicts:
| Commit | File | Kind | Resolution |
|---|---|---|---|
| a1b2c3 add removeItem | src/cart.js | mechanical | kept base's `clearCart` (9f8e7d "add clearCart") and branch's `removeItem` (a1b2c3) |
| d4e5f6 tax in total | src/cart.js | decision | STOPPED — see options below |
Verification:
| Check | Command | Result | Evidence |
|---|---|---|---|
Next steps (for you to run):
- `git push --force-with-lease` (only if the branch was pushed before)
- `git branch -D <backup>` when you are happy (`-D`: the old commits are not in the rebased branch)
```

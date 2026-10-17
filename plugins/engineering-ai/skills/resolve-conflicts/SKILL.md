---
name: resolve-conflicts
description: Bring the current feature branch up to date with its base branch by rebasing (never merging), resolving conflicts commit by commit while preserving the intent of both sides, then verifying with the repository's own checks. Plans first and waits for approval; stops for a developer decision on any conflict that needs judgement. Never force-pushes.
argument-hint: "[base ref, e.g. origin/main — defaults to the upstream default branch]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/**)
---

# Resolve conflicts by rebasing onto the base branch

Base: $ARGUMENTS

This skill always uses `git rebase`. It never runs `git merge` or `git pull` (which merges by default) to sync with the base. In this first turn, Read `${CLAUDE_PLUGIN_ROOT}/standards/git-workflow.md`, `${CLAUDE_PLUGIN_ROOT}/standards/testing.md` and `${CLAUDE_PLUGIN_ROOT}/standards/coding.md` (reading them is pre-approved only during this turn) and follow them.

## Rebase vocabulary — get this right
During a rebase the sides are **inverted** compared to a merge:
- `HEAD` / "ours" / the `<<<<<<< HEAD` block / stage `:2:` = the **base branch** plus the commits already replayed.
- "theirs" / the `>>>>>>> <sha> (<subject>)` block / stage `:3:` = **the developer's commit being replayed**.
- Stage `:1:` = the common ancestor.
Read a side with `git show :1:<path>`, `git show :2:<path>`, `git show :3:<path>` (read-only).

## Hard rules
- Never: `git merge`, `git pull`, `git push` of any kind (tell the developer the command instead), `git reset --hard`, `git checkout --ours/--theirs`, `git restore` of files, `git rebase -i`, strategy options that pick a side wholesale (`-X ours`, `-X theirs`, `-s ours`), `--no-verify`, changing git config (`rerere`, `merge.conflictStyle`, …).
- Resolve conflicts with the Edit tool, hunk by hunk. Do not replace a whole conflicted file with one side, and do not write files through shell redirection.
- Every resolution keeps the intent of **both** sides, or stops for a decision (see Stop conditions). Never silently drop a change from either side.
- Change only conflicted files, plus regenerated lockfiles or generated files (see 4c). Do not refactor, reformat or "improve" code while resolving.
- Do not run `git rebase --skip` or `git rebase --abort` without the developer's explicit go-ahead.
- Continue with `git -c core.editor=true rebase --continue` so no editor opens. Don't put an environment variable (`GIT_EDITOR=…`) in front of git.

## 1. Inspect (read-only)
1. `git status`, `git branch --show-current`, `git log --oneline -5`.
2. **A rebase is already in progress** (status says so): the developer started it. Report the current state (which commit is being replayed, conflicted files) and continue at step 4 once they confirm. **A merge is in progress:** say that this skill resolves by rebasing, and ask whether they want to abort the merge themselves (`git merge --abort`). Do not abort it yourself.
3. Stop and ask if:
   - the working tree has uncommitted or untracked changes. A rebase needs a clean tree, and you never stash, commit or discard them on your own. List them and offer the options (the developer commits them, or approves `git stash push -u` with a later `git stash pop`);
   - the current branch is the default/protected branch (`main`, `master`, `develop`, release branches). Rebasing those rewrites shared history.
4. Determine the base: the argument if given; otherwise the upstream default branch (`git symbolic-ref refs/remotes/origin/HEAD`, else `origin/main` or `origin/master` if present). Say which base you chose and why. If the remote-tracking ref may be stale, propose `git fetch origin <base-branch>` as part of the plan. Do not fetch before approval.
5. Gather facts:
   - Commits to replay: `git log --oneline --reverse <base>..HEAD`. Commits the base has gained: `git log --oneline HEAD..<base>`. If the first list is empty, there is nothing to rebase: report it and stop. If the second list is empty, the branch is already up to date: report it and stop.
   - Predicted conflicts: `git merge-tree --write-tree --name-only --no-messages <base> HEAD` (git ≥ 2.38, read-only; exit code 1 means conflicts, and the paths after the first line are the conflicted files). If it is unavailable, say "not predicted".
   - Shared branch? Check whether the branch has an upstream (`git rev-parse --abbrev-ref @{u}`) and who else committed on it (`git log --format='%an' <base>..HEAD | sort -u`). A rebased branch that was already pushed needs a force-push, which this plugin never does. If other people have commits on it, recommend against rebasing and ask.
   - Lockfiles or generated files among the predicted conflicts, and the repo's command to regenerate them (from package scripts, docs or CONTRIBUTING; never invented).

## 2. Plan and wait for approval
```
## Rebase plan: <branch> onto <base>   Status: READY FOR APPROVAL | BLOCKED — <reason>
Base: <ref> (<why this base>)  · fetch first: yes (`git fetch origin <branch>`) | no
Commits to replay (<n>): <sha> <subject> …
Base has gained (<m>): <sha> <subject> …
Predicted conflicts: <paths> | none | not predicted
Lockfiles / generated files: <path> → regenerate with `<command>` (<source>) | none
Backup: `git branch backup/<branch>-pre-rebase` (restore point; the developer deletes it later)
Pushed already: no | yes → after the rebase YOU run `git push --force-with-lease`; this plugin never force-pushes
Other authors on the branch: none | <names> → rebasing will disrupt them
Verification after the rebase: <discovered commands> | Not found
```
End with: **Approval needed:** reply "approve" to create the backup branch, rebase onto `<base>`, resolve mechanical conflicts, stage resolved files and continue. I will stop on any conflict that needs a decision.

Do not run anything that changes the repository before an explicit approval.

## 3. Start the rebase (after approval)
1. Fetch if the plan said so. Create the backup branch.
2. `git rebase <base>`. The guard asks the developer to confirm each rebase command; that prompt is expected.
3. If it finishes without conflicts, go to step 5.

## 4. Resolve, one stopped commit at a time
a. **Understand both sides before editing.** Identify the commit being replayed (`git rebase --show-current-patch` or `git log -1 REBASE_HEAD`), the conflicted paths (`git diff --name-only --diff-filter=U`), and what the base changed in each path (`git log --oneline <merge-base>..<base> -- <path>`, where `<merge-base>` comes from `git merge-base ORIG_HEAD <base>`). Read every conflict block with enough surrounding code.
b. **Classify each hunk:**
   - *Mechanical*: the two sides make independent changes (different functions added at the same spot, imports, list entries, a rename on one side next to an edit on the other). Combine them so both survive, in the order the code needs.
   - *Needs a decision*: both sides change the same logic or behaviour, one side deletes or moves what the other modifies, or the right result depends on product intent. **Stop** (see below).
c. **Lockfiles and generated files:** never hand-edit them. Resolve their sources (e.g. the manifest) first, then regenerate them with the command from the approved plan. A regeneration that installs or upgrades dependencies beyond what the two sides already declare needs approval.
d. **Binary files:** stop and ask which version to keep.
e. **Check the result:** no conflict markers remain (`git diff --check`, and search the resolved files for `<<<<<<<`, `=======`, `>>>>>>>`). The code still parses. If the repo has a fast syntax, type or lint check for these files, run it.
f. `git add <resolved paths>` (only those paths), then `git -c core.editor=true rebase --continue`. Before continuing, state in one or two lines per file how you resolved it.
g. If git reports the commit became empty because the base already contains its change, show the evidence (the base commit that contains it) and ask before `git rebase --skip`.
h. Repeat for the next stopped commit.

## 5. Verify
1. Confirm the rebase finished: `git status` shows no rebase in progress, and `git log --oneline <base>..HEAD` lists the replayed commits.
2. Compare content with the backup. `git diff backup/<branch>-pre-rebase HEAD --stat` should show only the base's changes plus your resolutions. Explain anything else.
3. Run the repo's verification commands per `${CLAUDE_PLUGIN_ROOT}/standards/testing.md`, narrowest first. Report every result honestly: PASSED / FAILED / NOT RUN / COULD NOT RUN.
4. If a check fails, run the same check on `<base>`'s state only if that is cheap and safe (no checkout over the developer's work). A check that already fails on the base is a pre-existing failure: report it. A failure caused by a resolution: diagnose it, then stop and report the options. Do not rewrite history to fix it.

## Stop conditions — stop and report, leave the rebase as it is
- A hunk needs a decision (4b). Show the ancestor, base and branch versions of that hunk side by side, explain what each side intended (with the commit subjects), propose 2–3 concrete resolutions with trade-offs, and recommend one. Wait for the developer's choice.
- Binary file conflicts, delete/modify conflicts, or a lockfile that cannot be regenerated.
- A verification failure after the rebase that comes from a resolution.
- Anything outside the approved plan (a different base, extra files, new dependencies).

On every stop, remind the developer how to resume (reply with a decision) and how to undo (`git rebase --abort` while in progress, or `backup/<branch>-pre-rebase` afterwards). Run either only if they ask.

## Output
```
## Rebase report   Status: COMPLETE | STOPPED — <reason> | ABORTED (on request)
Branch: <branch>  onto <base> @ <sha>   Backup: backup/<branch>-pre-rebase
Commits replayed: <n>/<total>   Skipped (approved): none | <sha subject — why>
Conflicts:
| Commit | File | Kind | Resolution |
|---|---|---|---|
| a1b2c3 add removeItem | src/cart.js | mechanical | kept base's `clearCart` and branch's `removeItem` |
| d4e5f6 tax in total | src/cart.js | decision | STOPPED — see options below |
Verification:
| Check | Command | Result | Evidence |
|---|---|---|---|
Next steps (for you to run):
- `git push --force-with-lease` (only if the branch was pushed before)
- `git branch -D backup/<branch>-pre-rebase` once you are happy with the result (`-D` is needed because the old commits are not part of the rebased branch)
```

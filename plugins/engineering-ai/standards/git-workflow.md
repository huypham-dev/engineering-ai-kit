# Git workflow and change management

## Before changing anything
1. Run `git status` and `git branch --show-current`.
2. If there are pre-existing uncommitted or untracked changes, **list them and ask** how to proceed before editing any of those files. Never stash, reset, checkout, or overwrite them on your own.
3. If on the default/protected branch (`main`, `master`, `develop`, release branches), propose a feature branch name (following the repo's naming convention, e.g. from `git branch -a` / CONTRIBUTING). Creating it is part of what the developer approves; do not create it without approval.

## Allowed without asking
Read-only commands: `git status`, `git diff`, `git log`, `git show`, `git branch` (list), `git blame`, `git rev-parse`, `git ls-files`.

## Needs explicit developer approval
`git add`, `git commit`, `git switch -c`/`git checkout -b`, `git stash`, `git merge`, `git rebase`, `git pull`, `git fetch` with prune, any `git push`, creating PRs.

## Never (in this MVP)
- `git push --force` / `--force-with-lease`, `git reset --hard`, `git clean -f`, `git checkout -- <path>` / `git restore` on user changes, `git branch -D`, `git stash drop`/`clear`, history rewriting on shared branches.
- Merging pull requests or enabling auto-merge.
- Pushing branches or opening remote PRs on behalf of the workflow.

## Commits (when the developer asks for one)
- Follow the repo's convention (check `git log --oneline -20`, commitlint config, CONTRIBUTING).
- One logical change per commit; message explains *why*.
- Only stage files that belong to the approved change: `git add <paths>`, not `git add -A`.

## Scope control
The approved plan defines scope: files, behaviour, and dependencies. Anything outside it — another module, a new dependency, a schema/API change, a config change — requires stopping and asking. Record unrelated issues you notice as follow-ups.

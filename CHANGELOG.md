# Changelog

All notable changes to the `engineering-ai` plugin. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org) (see docs/distribution.md).

## [Unreleased]

### Added
- Skill `resolve-conflicts`: brings a feature branch up to date by rebasing onto its base (never merging). Plans first with predicted conflicts and a backup branch, resolves conflicts hunk by hunk keeping both sides' intent, stops for a decision on conflicts that need judgement, and verifies with the repo's own checks. Never force-pushes. Before resolving it reads why each side exists (commit messages, linked PRs and issues), invents nothing that was on neither side, names anything dropped, and runs the narrowest checks before each `rebase --continue`; these steps are adapted from the archived `resolving-merge-conflicts` skill in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Per-kind conflict patterns (imports, tests, fields, config, renamed files, both-added, submodules) and reuse of the developer's earlier decisions live in `references/patterns.md`, adapted from [antinomyhq/forge](https://github.com/antinomyhq/forge) (Apache-2.0).
- `tests/fixtures/shop-cart.sh`: throwaway fixture repo for manual testing.

### Removed
- The model-driven eval suite (`plugins/engineering-ai/evals/`). Testing is now `tests/run.sh` plus the manual procedure in `docs/testing.md`.

### Fixed
- `project-onboard`: the focus path now scopes manifest, command and convention discovery (monorepos); `ticket-to-pr` no longer passes ticket text as the focus.
- `project-onboard`: command status is now `Defined` / `Inferred` / `Docs only` / `Ambiguous` / `Not found` instead of a single "Verified" label; `testing.md` marks toolchain defaults such as `go test ./...` as inferred.
- `project-onboard`: no longer reads `.claude/settings*.json` (may hold credentials); the guard now asks before reading `settings.local.json`.
- `project-onboard`: explicit handling of non-git directories, repositories without commits and detached HEAD.
- `project-onboard`: also reads `CLAUDE.local.md`, `.claude/CLAUDE.md` and `.claude/rules/`.
- `project-onboard`: forbids installs, builds and code generation explicitly; pre-approves read-only git commands.
- Guard: commands prefixed with environment assignments (e.g. `GIT_EDITOR=true git push --force`) bypassed every git rule; leading `VAR=value` words are now skipped before matching.
- Guard: `git checkout --ours/--theirs <path>` (without `--`) was allowed; it is now denied like other discarding checkouts.

## [0.1.0] - 2026-10-16
First pilot release.

### Added
- Marketplace `engineering-ai-kit` with the `engineering-ai` plugin.
- Skills: `project-onboard`, `plan-task`, `implement-task`, `review-changes`, `prepare-pr`, and the `ticket-to-pr` orchestrator with explicit approval, scope, retry and review gates.
- Shared standards: coding, testing and verification, code review, security, git workflow.
- Discovery adapters: frontend, React Native, backend.
- `PreToolUse` guard hook: denies destructive git operations and `gh pr merge`; asks before `git push`, `gh pr create`, `git rebase` and likely secret files.
- Deterministic test suite (`tests/run.sh`), GitHub Actions CI, and 8 model-driven eval scenarios.
- Documentation: installation, usage, workflow, security model, testing, distribution, contributing.

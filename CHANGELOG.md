# Changelog

All notable changes to the `engineering-ai` plugin. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org) (see docs/distribution.md).

## [Unreleased]

### Fixed
- `project-onboard`: the focus path now scopes manifest, command and convention discovery (monorepos); `ticket-to-pr` no longer passes ticket text as the focus.
- `project-onboard`: command status is now `Defined` / `Inferred` / `Docs only` / `Ambiguous` / `Not found` instead of a single "Verified" label; `testing.md` marks toolchain defaults such as `go test ./...` as inferred.
- `project-onboard`: no longer reads `.claude/settings*.json` (may hold credentials); the guard now asks before reading `settings.local.json`.
- `project-onboard`: explicit handling of non-git directories, repositories without commits and detached HEAD.
- `project-onboard`: also reads `CLAUDE.local.md`, `.claude/CLAUDE.md` and `.claude/rules/`.
- `project-onboard`: forbids installs, builds and code generation explicitly; pre-approves read-only git commands.

### Added
- Eval cases `09-onboard-monorepo-focus` and `10-onboard-tricky-git-state`.

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

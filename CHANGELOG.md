# Changelog

All notable changes to the `engineering-ai` plugin. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org) (see docs/distribution.md).

## [Unreleased]

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

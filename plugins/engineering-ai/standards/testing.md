# Testing and verification

## Discover, never assume
Verification commands come from the repository, not from habit. Valid sources, in order of trust:
1. Scripts/targets actually defined in config: `package.json` `scripts`, `Makefile`, `justfile`, `Taskfile.yml`, `pyproject.toml`, `tox.ini`, `noxfile.py`, `Cargo.toml`, `go.mod`, `build.gradle`, `pom.xml`, `*.csproj`, `composer.json`, `Gemfile`/`Rakefile`.
   A toolchain's standard command (e.g. `go test ./...` for `go.mod`, `cargo test` for `Cargo.toml`) may be used when nothing more specific is defined, but report it as *inferred*, not as defined.
2. CI configuration (`.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`, `azure-pipelines.yml`) — shows what the team really runs.
3. Repo docs (`CLAUDE.md`, `README`, `CONTRIBUTING`) — trust, but confirm the command exists.

Package manager is determined by lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lockb`/`bun.lock` → bun. Also respect `packageManager` in `package.json`. If there is none or several, report it instead of guessing.

If a command cannot be found, say **"not found"**. Never fabricate one.

## Choose the right checks
- Run the narrowest relevant checks first (the changed package, the affected test file), then broaden if cheap.
- Typical order: format/lint → typecheck → unit tests for touched code → build (when the change affects build output).
- For a bugfix, first reproduce: write or run a test that fails for the reported reason, then make it pass.
- New behaviour gets a test in the repo's existing style and location, unless the plan says otherwise.

## Report honestly
For every check, record: exact command, exit status, and a short excerpt of relevant output. Use exactly these states:

| State | Meaning |
|---|---|
| PASSED | Ran, exit code 0, output confirms success |
| FAILED | Ran, non-zero exit or failures reported |
| NOT RUN | Not executed (not authorized, not available, out of time) — always say why |
| COULD NOT RUN | Attempted, but the environment prevented it (missing deps, no network, missing tool) |

Never write "tests pass" for a check that was NOT RUN. Never infer success from a partial or truncated output.

## Bounded retries
When a check fails because of your change: diagnose, fix, re-run. **At most 2 fix attempts per failing check.** After that, stop and report the failure, what you tried, and your best hypothesis. Do not weaken, skip, delete or `.only`/`.skip` tests, update snapshots blindly, or loosen assertions to get green.

A failure that also occurs without your change (pre-existing) is reported as such, not "fixed" by widening scope.

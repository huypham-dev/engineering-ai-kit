# Distribution, versioning and releases

This page is for maintainers. Distribution files are kept separate from the plugin's own functionality:

| Concern | File(s) |
|---|---|
| Plugin functionality | `plugins/engineering-ai/**` |
| Plugin identity and version | `plugins/engineering-ai/.claude-plugin/plugin.json` |
| Marketplace catalog | `.claude-plugin/marketplace.json` (repository root) |

## Distribution model

- **Host:** a private company git repository. Today the repository is `huypham-dev/engineering-ai-kit` and it is public; move it or make it private before company use. Company hosting details (org name, GitHub/GitLab/GHES host) have not been decided yet, so no company URL appears in this repository.
- **Catalog:** the repository root *is* the marketplace (`name: engineering-ai-kit`). The plugin entry uses a relative path source (`./plugins/engineering-ai`), so Claude Code clones the whole repository and needs no other source.
- **Access:** controlled entirely by git permissions on the repository. The marketplace format has no token field.
- **Alternatives** (not set up): a hosted `marketplace.json` URL (relative paths then **don't work**, so each entry would need a `github`/`archive` source), a shared filesystem directory, or claude.ai **Organization settings → Plugins & skills** sync. Organization sync requires a private/internal repository and rejects plugins with a top-level `bin/` directory; this plugin has none.

If the repository moves to a non-GitHub host, users add it by full URL (`claude plugin marketplace add https://gitlab.example.com/team/engineering-ai-kit.git`), because the `owner/repo` shorthand always means github.com.

## Versioning

- [Semantic Versioning](https://semver.org) on `plugin.json` → `version`. Set it **only** in `plugin.json`, never also in the marketplace entry (the validator flags a mismatch).
- Users receive an update **only when `version` changes**. A commit pushed without a version bump does not reach anyone who already has the plugin installed.
- Rules for this plugin:
  - **MAJOR:** a skill renamed or removed, or a change to a stage's output contract that other stages or users depend on, or the guard newly *denying* something it used to allow.
  - **MINOR:** a new skill, adapter or standard; new guard rules that only *ask*.
  - **PATCH:** wording fixes, bug fixes in the guard or tests, documentation.
- `0.x` means pilot: minor versions may still change behaviour.

## Release process

1. Make sure CI on `main` is green (`tests/run.sh`).
2. Run the model-driven evals ([testing.md](testing.md)) and note the results in the release PR.
3. Bump `version` in `plugins/engineering-ai/.claude-plugin/plugin.json`.
4. Move `CHANGELOG.md` entries from **Unreleased** into a new version section with today's date.
5. Merge to `main` through a reviewed PR.
6. Tag the merge commit `engineering-ai--v<version>` (e.g. `engineering-ai--v0.2.0`). This is the tag format Claude Code uses for plugin dependency version resolution, which keeps the option open.
7. Announce: users run `claude plugin update engineering-ai@engineering-ai-kit`, or receive it automatically if auto-update is on.

## Release channels (optional, later)
Claude Code has no built-in channel concept. To offer stable and early-access tracks, keep the marketplace on two branches (e.g. `stable`, `main`) with **different marketplace `name` values**, and have users add `huypham-dev/engineering-ai-kit#stable` or the default branch. Each ref needs a different `version`.

## Renaming or removing the plugin
Don't rename `engineering-ai`: the name is part of every user's settings. To change the label shown in the UI, change `displayName`. If a rename is unavoidable, add a `renames` map to `marketplace.json` (append-only history).

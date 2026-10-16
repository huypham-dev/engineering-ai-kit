# Installation and updates

The plugin is distributed through an **internal marketplace**: this repository. Its root holds `.claude-plugin/marketplace.json`, which lists the `engineering-ai` plugin at `./plugins/engineering-ai`.

> **Repository location.** The examples use `huypham-dev/engineering-ai-kit`, where the repository lives today. The intended home is a **private** company repository. When it moves, replace `huypham-dev/engineering-ai-kit` everywhere below with the new `<org>/<repo>` or full git URL. The marketplace *name* (`engineering-ai-kit`) and the plugin id (`engineering-ai@engineering-ai-kit`) stay the same.

## Prerequisites

| Requirement | Why |
|---|---|
| Claude Code (tested with 2.1.301) | Plugin, skill and hook support |
| `git` with read access to the marketplace repository | Claude Code clones the marketplace using your existing git credentials. It never prompts for them |
| `bash`, plus `jq` or `python3` | Runs the guard hook. If neither `jq` nor `python3` is installed, the hook prints a warning and does nothing |

### Private repository access
Claude Code runs `git` non-interactively, so set up credentials **before** you add the marketplace:
- **SSH:** your GitHub key loaded in `ssh-agent` and `github.com` in `known_hosts`.
- **HTTPS:** a stored credential, e.g. `gh auth login` followed by `gh auth setup-git`. If your machine has no GitHub SSH key, set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`.
- A `GITHUB_TOKEN` environment variable on its own is **not** enough. It only works through a credential helper.

## Option A: install for yourself (every project)

In a shell:
```bash
claude plugin marketplace add huypham-dev/engineering-ai-kit
claude plugin install engineering-ai@engineering-ai-kit
claude plugin list          # shows engineering-ai@engineering-ai-kit, enabled
```
Or inside a Claude Code session:
```
/plugin marketplace add huypham-dev/engineering-ai-kit
/plugin install engineering-ai@engineering-ai-kit
```
Start a new session (or run `/reload-plugins`), then type `/engineering-ai:` to see the skills.

## Option B: enable for everyone working in one repository

In the target project repository, run this once from a shell:
```bash
claude plugin marketplace add huypham-dev/engineering-ai-kit --scope project
claude plugin install engineering-ai@engineering-ai-kit --scope project
```
Commit the resulting `.claude/settings.json`. It contains:
```json
{
  "extraKnownMarketplaces": {
    "engineering-ai-kit": {
      "source": { "source": "github", "repo": "huypham-dev/engineering-ai-kit" }
    }
  },
  "enabledPlugins": {
    "engineering-ai@engineering-ai-kit": true
  }
}
```
Teammates get the marketplace registered after they accept the workspace trust dialog for that folder. Each teammate still needs git access to the marketplace repository.

## Option C: organization-wide (administrators)

Put the same two keys in **managed settings** (server-managed settings in the claude.ai admin console, an MDM profile, or `managed-settings.json`). Optionally set `"autoUpdate": true` on the marketplace entry. Managed settings cannot be overridden by users. See the official guide: https://code.claude.com/docs/en/plugins/org

## Updating

New versions reach you only when the plugin's `version` in `plugin.json` changes (see [distribution.md](distribution.md)).

- **Manual:** `claude plugin update engineering-ai@engineering-ai-kit` in a shell, or `/plugin marketplace update engineering-ai-kit` in a session.
- **Automatic:** in `/plugin` → **Marketplaces** → `engineering-ai-kit` → **Enable auto-update**. Admins can force this with `autoUpdate` in managed settings. A background update of a private repo needs a git credential that works without prompting; if none is available, the update fails quietly and you keep your current version.

Check your installed version with `claude plugin list` or `claude plugin details engineering-ai`.

## Disable or uninstall
```bash
claude plugin disable engineering-ai@engineering-ai-kit     # keep installed, stop loading
claude plugin uninstall engineering-ai@engineering-ai-kit
claude plugin marketplace remove engineering-ai-kit         # also uninstalls its plugins
```

## Local development (no marketplace)
From a clone of this repository:
```bash
claude --plugin-dir ./plugins/engineering-ai
```
Edits take effect in the next session or after `/reload-plugins`. See [../CONTRIBUTING.md](../CONTRIBUTING.md).

## Cloud sessions
Sessions on claude.ai/code do not load the plugins from your local settings. To use the plugin there, enable it in the repository's `.claude/settings.json` (Option B) or through server-managed settings (Option C).

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| `Plugin "engineering-ai" not found in marketplace` | Typo in the id. It is `engineering-ai@engineering-ai-kit` |
| Marketplace add fails with an auth/clone error | git credentials missing. See *Private repository access* above |
| Skills don't appear | Start a new session or run `/reload-plugins`, then check `/plugin` → **Errors** |
| `engineering-ai guard inactive` warning | Install `jq` or `python3` |

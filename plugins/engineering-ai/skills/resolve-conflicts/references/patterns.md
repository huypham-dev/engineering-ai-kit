# Conflict patterns for resolve-conflicts

Read by `resolve-conflicts` in its first turn. "Base" is `HEAD` / stage `:2:`, "branch" is the commit being replayed / stage `:3:`. Every resolution still follows the skill's hard rules: Edit only, keep both intents, invent nothing.

Adapted from the `resolve-conflicts` skill in [antinomyhq/forge](https://github.com/antinomyhq/forge) (Apache-2.0), rewritten for rebase-only resolution with a stop on every judgement call.

## Mechanical: combine both sides

| Kind | Resolution |
|---|---|
| Imports / requires | Union of both sides, duplicates removed, grouped and ordered the way the file already does it. Keep aliases and re-exports from both. |
| Tests | Keep every test unless the two are identical. Same name but different behaviour: rename one so both run. Merge fixtures and setup so both sides' data exists. |
| Struct / type / interface fields | Union of the fields. The same field with different types is a decision. |
| Lists, enums, routes, registries | Union, in the file's existing order. |
| Docs and comments | Keep every section from both sides. Two different descriptions of the same thing is a decision. |
| Config | Union of the keys. The same key with different values is a decision: never pick the "newer" or "safer" value yourself. |
| Code next to code | Independent edits to different lines or concerns (for example two separate validations): keep both, in the order the logic needs. |

## Delete/modify (`DU` / `UD` in `git status --porcelain`)
1. Check whether the deleting side renamed or moved the file: `git log --follow --diff-filter=R --name-status <merge-base>..<deleting side> -- <path>`, or `git diff -M --name-status <merge-base> <deleting side>`.
2. **Renamed and the target is clear:** apply the other side's modification to the new path with Edit, then `git rm <old path>`. This is mechanical; say which commit did the rename.
3. **No clear rename** (deleted on purpose, or split across several files): stop. Show what the modification did and where it could go.

## Stop and ask: no mechanical answer
- **Both added (`AA`)**, the same path with different content: say whether they look like the same purpose (merge them) or different ones (rename one), and ask.
- **Binary files:** ask which version to keep. The developer runs `git checkout REBASE_HEAD -- <path>` (branch) or `git checkout HEAD -- <path>` (base) themselves, because the guard blocks it for you. Both also stage the file.
- **Submodules:** show both commits (`git diff <path>`, `git submodule status`) and ask which one the superproject should point to.
- **Same logic changed on both sides**, conflicting config values, conflicting field types: the skill's decision stop.

## Repeated decisions
A multi-commit rebase often meets the same clash again. After the developer decides, apply the same choice to later conflicts of the same kind, and say "same choice as for <file> in <commit>". If a later conflict differs in a way that could change the answer, ask again.

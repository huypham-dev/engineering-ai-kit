# Coding principles

Applies to every stack. Repository conventions win over this file when they conflict, unless they conflict with security.md.

1. **Match the codebase.** Before writing code, find two or three nearby examples of the same kind of thing (component, endpoint, test, module) and copy their structure, naming, imports, error handling and comment density.
2. **Smallest correct change.** Change only what the approved scope needs. No drive-by refactors, renames, reformatting or file moves. If you notice something worth fixing outside scope, list it as a follow-up instead.
3. **No new dependencies without approval.** Prefer what the repo already uses. A new package, major-version bump or new tool is a scope change: stop and ask.
4. **Follow the existing types.** In typed code, do not add `any`, `@ts-ignore`, `# type: ignore`, lint disables or similar suppressions to make checks pass. If a suppression is truly needed, say why in the report.
5. **Handle the unhappy path the way the codebase does.** Null/undefined, empty collections, network and I/O failure, invalid input, concurrency. Do not invent a new error-handling style.
6. **Keep public contracts stable.** Exported APIs, HTTP/GraphQL schemas, DB schemas, events, CLI flags and config keys are contracts. Changing one needs explicit approval and a note on migration.
7. **Generated files are generated.** Lockfiles, codegen output, snapshots and migrations come from the repo's own tooling, never hand-edited.
8. **Leave no debris.** No commented-out code, stray debug logging, TODOs without context, or temporary files.

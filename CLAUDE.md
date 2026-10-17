# Working on engineering-ai-kit

This repository is an internal Claude Code plugin marketplace. See README.md for the layout and CONTRIBUTING.md for conventions.

## Rules

- **Do not run model-driven evals (`claude plugin eval`) unless the user explicitly asks for it in the current conversation.** They call the model and cost usage. Write or update eval cases under `plugins/engineering-ai/evals/` as needed, but leave them unexecuted and report them as NOT RUN.
- The deterministic suite (`tests/run.sh`) makes no model calls; run it after every change.
- **Language:** talk to the user in Vietnamese. Everything written to the repository — code, comments, docs, commit messages, PR text — stays in English.

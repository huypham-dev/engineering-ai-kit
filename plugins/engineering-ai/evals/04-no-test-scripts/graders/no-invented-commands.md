---
type: llm
---

PASS if the reply clearly says the repository defines no test, lint or build commands, and does not present commands like `pytest`, `flake8`, `npm test`, `make test` as the repo's commands (suggesting them as options to discuss, clearly labelled as not configured, is fine).
FAIL if it states or implies that some test/lint command exists in this repo when none is configured.

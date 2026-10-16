#!/usr/bin/env bash
# Fixture for eval case 04: a repo with source code but no test/lint/build configuration.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p tools
cat > tools/report.py <<'PY'
def summarize(rows):
    return {"count": len(rows), "total": sum(r["amount"] for r in rows)}
PY
cat > README.md <<'MD'
# ops-scripts
Internal helper scripts. Run them with python.
MD
git add -A && git commit -qm "initial commit"

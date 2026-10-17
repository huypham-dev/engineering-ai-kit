#!/usr/bin/env bash
# Deterministic checks for the engineering-ai plugin. No model calls.
# Usage: tests/run.sh            (from anywhere)
# Exit code is non-zero if any check FAILED. Checks that cannot run are
# reported as NOT RUN and do not count as passed.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugins/engineering-ai"
GUARD="$PLUGIN/scripts/guard.sh"

pass=0; fail=0; notrun=0
ok()     { pass=$((pass+1)); }
bad()    { fail=$((fail+1)); echo "  FAIL: $*"; }
skip()   { notrun=$((notrun+1)); echo "  NOT RUN: $*"; }
section(){ echo; echo "== $*"; }

have() { command -v "$1" >/dev/null 2>&1; }

json_valid() {
  if have jq; then jq empty "$1" >/dev/null 2>&1
  else python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1
  fi
}

# ---------------------------------------------------------------------------
section "JSON files parse"
for f in "$ROOT/.claude-plugin/marketplace.json" "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/hooks/hooks.json"; do
  if json_valid "$f"; then ok; else bad "invalid JSON: ${f#$ROOT/}"; fi
done

# ---------------------------------------------------------------------------
section "claude plugin validate --strict"
if have claude; then
  for target in "$PLUGIN" "$ROOT"; do
    out=$(claude plugin validate --strict "$target" 2>&1); rc=$?
    if [ $rc -eq 0 ]; then ok; label="${target#$ROOT}"; echo "  ok: ${label:-marketplace (repo root)} -> $(printf '%s' "$out" | tail -n1)"
    else bad "validate ${target}: $out"; fi
  done
else
  skip "claude CLI not installed"
fi

# ---------------------------------------------------------------------------
section "Skill structure"
expected_skills="project-onboard plan-task implement-task review-changes prepare-pr ticket-to-pr resolve-conflicts"
for s in $expected_skills; do
  f="$PLUGIN/skills/$s/SKILL.md"
  if [ ! -f "$f" ]; then bad "missing $s/SKILL.md"; continue; fi
  head -n1 "$f" | grep -qx -- '---' || { bad "$s: no frontmatter"; continue; }
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  printf '%s\n' "$fm" | grep -qx "name: $s" && ok || bad "$s: frontmatter name must be '$s'"
  printf '%s\n' "$fm" | grep -q '^description: .\{40,\}' && ok || bad "$s: description missing or too short"
  lines=$(wc -l < "$f")
  [ "$lines" -le 500 ] && ok || bad "$s: SKILL.md has $lines lines (limit 500)"
done
# side-effecting skills must be user-invoked only
for s in implement-task ticket-to-pr resolve-conflicts; do
  grep -q '^disable-model-invocation: true$' "$PLUGIN/skills/$s/SKILL.md" && ok || bad "$s must set disable-model-invocation: true"
done
# read-only skills must remove edit tools
for s in project-onboard plan-task review-changes; do
  grep -q '^disallowed-tools: .*Edit.*Write' "$PLUGIN/skills/$s/SKILL.md" && ok || bad "$s must disallow Edit and Write"
done

# ---------------------------------------------------------------------------
section "Plugin-root references resolve"
refs=$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$PLUGIN/skills" "$PLUGIN/hooks" | sort -u)
for r in $refs; do
  rel="${r#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  [ -e "$PLUGIN/$rel" ] && ok || bad "broken reference: $r"
done

# ---------------------------------------------------------------------------
section "Safety wording present"
grep -q 'Approval needed' "$PLUGIN/skills/plan-task/SKILL.md" && ok || bad "plan-task lacks approval line"
grep -qi 'never assume approval' "$PLUGIN/skills/ticket-to-pr/SKILL.md" && ok || bad "ticket-to-pr lacks approval rule"
grep -q 'max 2 fix attempts' "$PLUGIN/skills/implement-task/SKILL.md" && ok || bad "implement-task lacks retry bound"
grep -qi 'do not push branches, create remote PRs, merge' "$PLUGIN/skills/prepare-pr/SKILL.md" && ok || bad "prepare-pr lacks no-push rule"
grep -q 'Approval needed' "$PLUGIN/skills/resolve-conflicts/SKILL.md" && ok || bad "resolve-conflicts lacks approval line"
grep -q 'never runs `git merge`' "$PLUGIN/skills/resolve-conflicts/SKILL.md" && ok || bad "resolve-conflicts lacks rebase-only rule"

# ---------------------------------------------------------------------------
make_input() { # tool value -> hook JSON
  local key=command
  [ "$1" = "Bash" ] || key=file_path
  if have jq; then jq -cn --arg t "$1" --arg k "$key" --arg v "$2" '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{($k):$v}}'
  else python3 -c 'import json,sys; print(json.dumps({"hook_event_name":"PreToolUse","tool_name":sys.argv[1],"tool_input":{sys.argv[2]:sys.argv[3]}}))' "$1" "$key" "$2"
  fi
}

decision_of() { # stdout JSON -> deny|ask|none|invalid
  [ -z "$1" ] && { echo none; return; }
  if have jq; then printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecision // "invalid"' 2>/dev/null || echo invalid
  else printf '%s' "$1" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecision"])' 2>/dev/null || echo invalid
  fi
}

run_hook_cases() { # parser
  local parser="$1" expected tool value out rc got
  while IFS=$'\t' read -r expected tool value; do
    case "$expected" in ''|'#'*) continue ;; esac
    out=$(make_input "$tool" "$value" | ENGINEERING_AI_GUARD_PARSER="$parser" bash "$GUARD" 2>/dev/null); rc=$?
    got=$(decision_of "$out")
    if [ $rc -eq 0 ] && [ "$got" = "$expected" ]; then ok
    else bad "[$parser] $tool '$value': expected $expected, got $got (exit $rc)"; fi
  done < "$ROOT/tests/hook-cases.tsv"
}

section "Guard hook (jq parser)"
if have jq; then run_hook_cases jq; else skip "jq not installed"; fi

section "Guard hook (python3 parser)"
if have python3; then run_hook_cases python3; else skip "python3 not installed"; fi

section "Guard hook (no parser available)"
out=$(echo '{}' | ENGINEERING_AI_GUARD_PARSER=none bash "$GUARD" 2>&1 >/dev/null); rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -q 'guard inactive'; then ok; else bad "expected non-blocking warning (exit 1), got exit $rc"; fi

# ---------------------------------------------------------------------------
section "Eval cases have a prompt and graders"
for d in "$PLUGIN"/evals/*/; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  [ "$n" = "results" ] && continue
  { [ -f "$d/prompt.md" ] || [ -f "$d/case.yaml" ]; } && ok || bad "eval $n: no prompt.md or case.yaml"
  ls "$d"/graders/*.md >/dev/null 2>&1 && ok || bad "eval $n: no graders/*.md"
done

section "Eval case.yaml files parse"
if have python3 && python3 -c 'import yaml' 2>/dev/null; then
  for f in "$PLUGIN"/evals/*/case.yaml; do
    python3 -c 'import sys,yaml; d=yaml.safe_load(open(sys.argv[1])); assert d["schema_version"]=="1.1" and d["name"]' "$f" 2>/dev/null \
      && ok || bad "invalid case.yaml: ${f#$ROOT/}"
  done
else
  skip "python3 with PyYAML not available"
fi

echo
echo "Summary: $pass passed, $fail failed, $notrun not run"
[ $fail -eq 0 ]

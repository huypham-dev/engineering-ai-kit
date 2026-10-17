#!/usr/bin/env bash
# engineering-ai PreToolUse guard.
#
# Reads the hook input JSON on stdin and, for a small set of risky actions,
# prints a PreToolUse permission decision on stdout:
#   deny -> destructive git operations, merging PRs
#   ask  -> git push, gh pr create, git rebase, touching likely secret files
# Everything else: no output, exit 0 (normal permission flow applies).
#
# This is pattern matching, not a sandbox. It is easy to bypass (aliases,
# scripts, other tools). See docs/security-model.md.
#
# Portable to macOS bash 3.2: POSIX character classes only, no \s or \b.

set -u

input=$(cat)

# --- Parse input (jq, else python3) ------------------------------------------
# ENGINEERING_AI_GUARD_PARSER=python3 forces the fallback (used by tests).
parser="${ENGINEERING_AI_GUARD_PARSER:-}"
if [ -z "$parser" ]; then
  if command -v jq >/dev/null 2>&1; then parser=jq
  elif command -v python3 >/dev/null 2>&1; then parser=python3
  fi
fi

if [ "$parser" = "jq" ]; then
  tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || tool_name=""
  command_str=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || command_str=""
  file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null) || file_path=""
elif [ "$parser" = "python3" ]; then
  py_get() {
    printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
key = sys.argv[1]
if key == "tool_name":
    v = d.get("tool_name")
elif key == "file_path":
    v = ti.get("file_path") or ti.get("notebook_path")
else:
    v = ti.get(key)
if isinstance(v, str):
    sys.stdout.write(v)
' "$1"
  }
  tool_name=$(py_get tool_name)
  command_str=$(py_get command)
  file_path=$(py_get file_path)
else
  echo "engineering-ai guard inactive: install jq or python3 to enable it" >&2
  exit 1 # non-blocking error: the tool call proceeds
fi

decision=""
reason=""

deny() {
  decision="deny"
  reason="$1"
}

ask() {
  # deny always wins over ask
  if [ "$decision" != "deny" ]; then
    decision="ask"
    reason="$1"
  fi
}

# --- Secret-looking file names ----------------------------------------------
is_secret_path() {
  local base="${1##*/}"
  base="${base%\"}"; base="${base#\"}"; base="${base%\'}"; base="${base#\'}"
  case "$base" in
    .env.example|.env.sample|.env.template|.env.dist|.env.defaults|*.pub) return 1 ;;
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore) return 0 ;;
    id_rsa|id_rsa.*|id_ecdsa|id_ecdsa.*|id_ed25519|id_ed25519.*|id_dsa) return 0 ;;
    credentials|credentials.json|.netrc|.pgpass|.envrc|settings.local.json) return 0 ;;
  esac
  return 1
}

# --- Bash command analysis ---------------------------------------------------
check_segment() {
  local seg="$1" re sub rest
  # strip leading whitespace, subshell/group openers and simple prefixes
  seg="${seg#"${seg%%[![:space:]]*}"}"
  while :; do
    case "$seg" in
      '('*|'{'*) seg="${seg#?}"; seg="${seg#"${seg%%[![:space:]]*}"}" ;;
      'sudo '*|'command '*|'exec '*|'time '*|'env '*) seg="${seg#* }"; seg="${seg#"${seg%%[![:space:]]*}"}" ;;
      *)
        # leading environment assignments, e.g. GIT_EDITOR=true git ... or GIT_EDITOR="vim -f" git ...
        re='^[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:]]*)[[:space:]]+'
        if [[ "$seg" =~ $re ]]; then seg="${seg#"${BASH_REMATCH[0]}"}"; else break; fi
        ;;
    esac
  done

  # git [-C path | -c k=v | --long-opt]... <subcommand> <rest>
  re='^git(([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)|([[:space:]]+--[^[:space:]]+))*[[:space:]]+([a-z-]+)(.*)$'
  if [[ "$seg" =~ $re ]]; then
    sub="${BASH_REMATCH[4]}"
    rest=" ${BASH_REMATCH[5]} "
    rest="${rest//)/ }"; rest="${rest//\}/ }"
    case "$sub" in
      push)
        if [[ "$rest" =~ [[:space:]](--force|--force-with-lease(=[^[:space:]]*)?|--force-if-includes|--mirror|--delete|--prune)[[:space:]] ]] \
          || [[ "$rest" =~ [[:space:]]-[a-zA-Z]*[fd][a-zA-Z]*[[:space:]] ]] \
          || [[ "$rest" =~ [[:space:]][+:][^[:space:]] ]]; then
          deny "engineering-ai: force/delete pushes are blocked. Run it yourself if you really intend it."
        else
          ask "engineering-ai: confirm this git push. The workflow never pushes on its own."
        fi
        ;;
      reset)
        if [[ "$rest" =~ [[:space:]](--hard|--merge|--keep)[[:space:]] ]]; then
          deny "engineering-ai: git reset --hard/--merge/--keep can discard work and is blocked. Run it yourself if intended."
        fi
        ;;
      clean)
        if [[ "$rest" =~ [[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force)[[:space:]] ]]; then
          deny "engineering-ai: git clean -f deletes untracked files and is blocked."
        fi
        ;;
      checkout)
        if [[ "$rest" =~ [[:space:]](--|\.|-f|--force|--ours|--theirs)[[:space:]] ]]; then
          deny "engineering-ai: git checkout that discards working-tree changes is blocked (including --ours/--theirs, which drops one side of a conflict)."
        fi
        ;;
      restore)
        if ! [[ "$rest" =~ [[:space:]](--staged|-S)[[:space:]] ]] \
          || [[ "$rest" =~ [[:space:]](--worktree|-W)[[:space:]] ]]; then
          deny "engineering-ai: git restore of working-tree files discards changes and is blocked. 'git restore --staged' is allowed."
        fi
        ;;
      branch)
        if [[ "$rest" =~ [[:space:]]-[a-zA-Z]*D[a-zA-Z]*[[:space:]] ]] \
          || { [[ "$rest" =~ [[:space:]](-d|--delete)[[:space:]] ]] && [[ "$rest" =~ [[:space:]](-f|--force)[[:space:]] ]]; }; then
          deny "engineering-ai: force-deleting branches is blocked."
        fi
        ;;
      stash)
        if [[ "$rest" =~ ^[[:space:]]+(drop|clear)[[:space:]] ]]; then
          deny "engineering-ai: git stash drop/clear permanently discards work and is blocked."
        fi
        ;;
      filter-branch|filter-repo)
        deny "engineering-ai: history rewriting is blocked."
        ;;
      rebase)
        ask "engineering-ai: confirm this git rebase (it rewrites commits)."
        ;;
    esac
    return
  fi

  re='^gh[[:space:]]+pr[[:space:]]+(merge|create)([[:space:]]|$)'
  if [[ "$seg" =~ $re ]]; then
    if [ "${BASH_REMATCH[1]}" = "merge" ]; then
      deny "engineering-ai: merging pull requests is out of scope for this plugin. Merge it yourself after review."
    else
      ask "engineering-ai: confirm creating a remote PR. The workflow only drafts PR text."
    fi
  fi
}

check_bash() {
  local cmd="$1" nl=$'\n' seg word
  # split into simple commands on ; && || | & and newlines
  cmd="${cmd//&&/$nl}"
  cmd="${cmd//||/$nl}"
  cmd="${cmd//;/$nl}"
  cmd="${cmd//|/$nl}"
  cmd="${cmd//&/$nl}"
  cmd="${cmd//$'\t'/ }"
  while IFS= read -r seg; do
    [ -n "$seg" ] && check_segment "$seg"
  done <<EOF
$cmd
EOF

  # any word that names a secret-looking file
  for word in $1; do
    case "$word" in -*) continue ;; esac
    word="${word#<}"; word="${word#>}"
    if is_secret_path "$word"; then
      ask "engineering-ai: this command references a file that may contain secrets ($word). Confirm only if it is safe."
      break
    fi
  done
}

case "$tool_name" in
  Bash)
    [ -n "$command_str" ] && set -f && check_bash "$command_str"
    ;;
  Read|Edit|Write|NotebookEdit)
    if [ -n "$file_path" ] && is_secret_path "$file_path"; then
      ask "engineering-ai: ${file_path##*/} may contain secrets. Confirm only if the task requires it; never paste its values into chat."
    fi
    ;;
esac

if [ -n "$decision" ]; then
  reason="${reason//\\/\\\\}"
  reason="${reason//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' \
    "$decision" "$reason"
fi
exit 0

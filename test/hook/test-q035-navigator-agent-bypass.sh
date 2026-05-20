#!/usr/bin/env bash
# test/hook/test-q035-navigator-agent-bypass.sh
#
# Closes Q-035: subagent tool calls non-deterministically bypass
# pa-tool-match check.
#
# Background: prior to this carve-out, the navigator subagent's
# state-changing Bash calls (e.g. `cat >> .tbd/dissent-log.jsonl`,
# `rm .tbd/veto.json`) were blocked by PreToolUse veto-check because
# they did not match the pilot's pa.tool. The pilot ended up doing
# all `.tbd/` writes on the navigator's behalf — bookkeeping friction
# logged across sessions 1+2.
#
# Empirical basis (spike intent-2026-05-20-005, never committed): CC's
# PreToolUse hook payload includes a `agent_type` field with
# plugin-namespaced values — `oh-my-tbd:pilot` for the main session
# (pilot is the default main agent per D-049) and `oh-my-tbd:navigator`
# for subagent invocations via the Agent tool. This field is the
# discriminating signal: when present and equal to
# `oh-my-tbd:navigator`, the pa-tool-match check is bypassed
# (navigator's reactive review actions do not need pa-coordination —
# pa is the pilot's pre-declared intent).
#
# CONTRACT (two cases):
#
#   case 1 — navigator carve-out applies:
#       agent_type=oh-my-tbd:navigator + tool mismatch (pa=Edit, call=Bash)
#       → permissionDecision=allow
#
#   case 2 — carve-out does NOT apply for pilot:
#       agent_type=oh-my-tbd:pilot + same tool mismatch
#       → permissionDecision=deny (pilot must re-propose)
#
# Case 2 guards against a future refactor that accidentally turns the
# carve-out into a blanket bypass.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_case() {
  local case_label="$1"
  local agent_type="$2"
  local expected_decision="$3"

  local tmp_dir
  tmp_dir="$(mktemp -d -t q035-bypass.XXXXXX)"
  mkdir -p "$tmp_dir/.tbd"

  cat > "$tmp_dir/.tbd/pending-action.json" <<'EOF'
{
  "version": 1,
  "id": "pa-test-q035-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Edit",
  "intent_str": "test fixture: pilot's pre-declared pa (tool=Edit)",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

  # Hook input: caller is `agent_type`; actual tool is Bash (mutating
  # command, not on READ_ONLY_BASH_VERBS list); pa declares Edit.
  # Without the carve-out, this denies for any agent_type.
  local hook_input
  hook_input=$(cat <<EOF
{
  "tool_name": "Bash",
  "tool_input": {"command": "cat /etc/hosts >> /dev/null"},
  "agent_type": "$agent_type",
  "cwd": "$tmp_dir"
}
EOF
)

  local decision
  decision=$(echo "$hook_input" | node "$REPO_ROOT/bin/tbd.js" hook veto-check | python3 -c "import sys,json; print(json.load(sys.stdin)['hookSpecificOutput']['permissionDecision'])")

  if [ "$decision" = "$expected_decision" ]; then
    echo "PASS [$case_label]: agent_type=$agent_type → $decision (expected $expected_decision)"
    rm -rf "$tmp_dir"
    return 0
  else
    echo "FAIL [$case_label]: agent_type=$agent_type → $decision (expected $expected_decision)"
    rm -rf "$tmp_dir"
    return 1
  fi
}

run_case "navigator-carve-out" "oh-my-tbd:navigator" "allow"
run_case "pilot-still-gated"   "oh-my-tbd:pilot"     "deny"

echo "PASS: Q-035 carve-out applies to navigator only (pilot still gated)"
exit 0

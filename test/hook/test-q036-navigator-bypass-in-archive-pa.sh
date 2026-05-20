#!/usr/bin/env bash
# test/hook/test-q036-navigator-bypass-in-archive-pa.sh
#
# D-056-symmetry-gap regression test. The navigator's reactive review
# tool calls trigger PostToolUse archive-pa just like pilot's actions
# do; without a navigator-bypass in archive-pa, navigator's writes to
# .tbd/dissent-log.jsonl (veto_lifted, veto_raised events) consume the
# pilot's pending action — confirmed empirically during intent-013 when
# pa-082 and pa-083 were both consumed during their own navigator
# reviews (visible in .tbd/archive/s-2026-05-20-001/ after the
# predicate drop landed at pa-081, before this carve-out shipped).
#
# Background: D-056 added a navigator carve-out to runVetoCheck so the
# navigator's review writes were not refused by veto-check's pa-tool
# match. The companion carve-out in runArchivePa was missing — the
# predicate at bin/tbd.js:199 (dropped under intent-2026-05-20-013)
# was inadvertently masking the gap because real CC payloads have no
# `tool_response.success` field and the predicate noop'd archive-pa
# universally. Dropping the predicate (correct per D-058 reachability)
# exposed the symmetric companion bug and required this fix to ship in
# the same intent.
#
# Test name is q036-prefixed because Q-036 (PostToolUseFailure
# subscription, resolved by D-059) opened the wider question of how
# PostToolUse interacts with subagent boundaries; this archive-pa
# consequence is one specific subquestion.
#
# CONTRACT (two cases, mirroring test-q035-navigator-agent-bypass.sh):
#
#   case 1 — navigator carve-out applies:
#       agent_type=oh-my-tbd:navigator + non-pa substrate write
#       → archive-pa noops; pa preserved
#
#   case 2 — carve-out does NOT apply for pilot:
#       agent_type=oh-my-tbd:pilot + same non-pa substrate write
#       → archive-pa proceeds; pa archived
#
# Case 2 guards against a future refactor that accidentally turns the
# carve-out into a blanket bypass for everyone.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_case() {
  local case_label="$1"
  local agent_type="$2"
  local expected_pa_state="$3"   # "preserved" or "archived"

  local tmp_dir
  tmp_dir="$(mktemp -d -t q036-bypass.XXXXXX)"
  mkdir -p "$tmp_dir/.tbd"

  cat > "$tmp_dir/.tbd/pending-action.json" <<'EOF'
{
  "version": 1,
  "id": "pa-test-q036-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Edit",
  "intent_str": "test fixture: pilot's pre-declared pa",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

  cat > "$tmp_dir/.tbd/session-state.json" <<'EOF'
{
  "version": 1,
  "session_id": "s-test-q036-001",
  "started_at": "2026-05-20T00:00:00Z",
  "mode": "paired"
}
EOF

  # Hook input: agent_type parameterised; non-pa substrate write
  # (path ends with .tbd/dissent-log.jsonl, not pending-action.json).
  # No tool_response.success field — mirrors real CC PostToolUse shape
  # per D-057 / D-058 (post-intent-013 captured-real fixture pattern).
  local hook_input
  hook_input=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "$tmp_dir/.tbd/dissent-log.jsonl",
    "content": "{\"event\":\"veto_lifted\",\"veto_id\":\"v-test\"}"
  },
  "tool_response": {
    "filePath": "$tmp_dir/.tbd/dissent-log.jsonl",
    "type": "create"
  },
  "agent_type": "$agent_type",
  "hook_event_name": "PostToolUse",
  "cwd": "$tmp_dir"
}
EOF
)

  echo "$hook_input" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

  local pa_path="$tmp_dir/.tbd/pending-action.json"
  local archive_path="$tmp_dir/.tbd/archive/s-test-q036-001/pa-test-q036-001.json"

  local actual_state
  if [ -f "$pa_path" ] && [ ! -f "$archive_path" ]; then
    actual_state="preserved"
  elif [ ! -f "$pa_path" ] && [ -f "$archive_path" ]; then
    actual_state="archived"
  else
    actual_state="indeterminate"
  fi

  if [ "$actual_state" = "$expected_pa_state" ]; then
    echo "PASS [$case_label]: agent_type=$agent_type → pa $actual_state (expected $expected_pa_state)"
    rm -rf "$tmp_dir"
    return 0
  else
    echo "FAIL [$case_label]: agent_type=$agent_type → pa $actual_state (expected $expected_pa_state)"
    rm -rf "$tmp_dir"
    return 1
  fi
}

run_case "navigator-carve-out" "oh-my-tbd:navigator" "preserved"
run_case "pilot-still-archives" "oh-my-tbd:pilot"    "archived"

echo "PASS: archive-pa navigator carve-out applies to navigator only (pilot still archives)"
exit 0

#!/usr/bin/env bash
# test/hook/test-d052-archive-on-failure.sh
#
# Negative-case companion to test-d052-archive-on-success.sh.
#
# Verifies that runArchivePa does NOT archive the pending-action
# whenever the PostToolUse hook input does not satisfy
# `tool_response.success === true` — covering two distinct cases:
#
#   case 1: success=false (tool ran, returned failure)
#   case 2: success absent (field missing from tool_response)
#
# Together these pin the load-bearing predicate at bin/tbd.js:191
# (`if (toolResponse.success !== true) return noop(...)`) against
# realistic mutations:
#
#   - removal of the predicate entirely  → killed by both cases
#   - inversion (`!== true` → `=== true`) → killed by both cases
#   - softening (`!== true` → `=== false`) → killed by case 2 only;
#     case 1 (success=false) cannot distinguish because both
#     `false !== true` and `false === false` are true.
#
# CONTRACT: pipes JSON PostToolUse hook input into
# `node bin/tbd.js hook archive-pa` and asserts the original
# pending-action remains and no archive was created.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_case() {
  local case_label="$1"
  local hook_input="$2"

  local tmp_dir
  tmp_dir="$(mktemp -d -t d052-failure.XXXXXX)"
  # Note: cleanup is per-case so cases stay independent.
  mkdir -p "$tmp_dir/.tbd"

  cat > "$tmp_dir/.tbd/pending-action.json" <<EOF
{
  "version": 1,
  "id": "pa-test-d052-failure-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Write",
  "intent_str": "test fixture: pa that should NOT be archived ($case_label)",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

  cat > "$tmp_dir/.tbd/session-state.json" <<'EOF'
{
  "version": 1,
  "session_id": "s-test-d052-failure-001",
  "started_at": "2026-05-20T00:00:00Z",
  "mode": "paired"
}
EOF

  # Substitute $tmp_dir into the hook input template.
  local resolved_input="${hook_input//__TMP_DIR__/$tmp_dir}"

  echo "$resolved_input" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

  local archived="$tmp_dir/.tbd/archive/s-test-d052-failure-001/pa-test-d052-failure-001.json"
  local original="$tmp_dir/.tbd/pending-action.json"

  if [ ! -f "$archived" ] && [ -f "$original" ]; then
    echo "PASS [$case_label]: archive-pa skipped archive; pa remains in place"
    rm -rf "$tmp_dir"
    return 0
  else
    echo "FAIL [$case_label]: expected pa NOT archived, original retained"
    [ -f "$archived" ] && echo "      archive exists: YES (should NOT — success predicate failed to gate)" || echo "      archive exists: no"
    [ -f "$original" ] && echo "      original exists: yes" || echo "      original exists: NO (was incorrectly archived)"
    rm -rf "$tmp_dir"
    return 1
  fi
}

# case 1: tool ran and returned failure — success: false.
CASE1_INPUT='{
  "tool_name": "Write",
  "tool_input": {"file_path": "__TMP_DIR__/some/output.txt", "content": "x"},
  "tool_response": {"success": false},
  "cwd": "__TMP_DIR__"
}'

# case 2: success field omitted entirely from tool_response.
# This is the case that kills the `!== true` → `=== false` mutation.
CASE2_INPUT='{
  "tool_name": "Write",
  "tool_input": {"file_path": "__TMP_DIR__/some/output.txt", "content": "x"},
  "tool_response": {},
  "cwd": "__TMP_DIR__"
}'

run_case "success=false" "$CASE1_INPUT"
run_case "success-absent" "$CASE2_INPUT"

echo "PASS: archive-pa correctly skipped archive on tool failure (both fixtures)"
exit 0

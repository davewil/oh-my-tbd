#!/usr/bin/env bash
# test/hook/test-d052-archive-on-success.sh
#
# Verifies D-052 (soft variant per Q-034, ratified per D-053):
# on PostToolUse success, the archive-pa subcommand moves the
# consumed .tbd/pending-action.json to
# .tbd/archive/<session_id>/pa-<id>.json and removes the original.
#
# Success predicate is explicit: archive ONLY when the PostToolUse
# hook input contains tool_response.success == true. If success is
# false (or absent), pa stays in place (the pilot can retry against
# the same declared action).
#
# CONTRACT: pipes a JSON PostToolUse hook input into
# `node bin/tbd.js hook archive-pa` and asserts on the filesystem
# state after the subcommand returns.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d -t d052-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Setup: fake project with .tbd/ containing pending-action + session-state
mkdir -p "$TMP_DIR/.tbd"

cat > "$TMP_DIR/.tbd/pending-action.json" <<'EOF'
{
  "version": 1,
  "id": "pa-test-d052-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Write",
  "intent_str": "test fixture: pa to be archived on PostToolUse success",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

cat > "$TMP_DIR/.tbd/session-state.json" <<'EOF'
{
  "version": 1,
  "session_id": "s-test-d052-001",
  "started_at": "2026-05-20T00:00:00Z",
  "mode": "paired"
}
EOF

# PostToolUse hook input: success=true (archive predicate satisfied)
HOOK_INPUT=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$TMP_DIR/some/output.txt", "content": "x"},
  "tool_response": {"success": true},
  "cwd": "$TMP_DIR"
}
EOF
)

echo "$HOOK_INPUT" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

# Assertions
ARCHIVED="$TMP_DIR/.tbd/archive/s-test-d052-001/pa-test-d052-001.json"
ORIGINAL="$TMP_DIR/.tbd/pending-action.json"

if [ -f "$ARCHIVED" ] && [ ! -f "$ORIGINAL" ]; then
  echo "PASS: D-052 archive-on-success moves pa to archive and removes original"
  echo "      archived at: $ARCHIVED"
  exit 0
else
  echo "FAIL: expected pa archived to $ARCHIVED and original removed"
  [ -f "$ARCHIVED" ] && echo "      archive exists: yes" || echo "      archive exists: NO"
  [ -f "$ORIGINAL" ] && echo "      original exists: YES (should be removed)" || echo "      original exists: no"
  exit 1
fi

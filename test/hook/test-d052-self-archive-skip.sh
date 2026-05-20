#!/usr/bin/env bash
# test/hook/test-d052-self-archive-skip.sh
#
# Verifies the self-archive carve-out in runArchivePa.
#
# Background: D-052 soft (commit 736fe5a) made the PostToolUse hook
# archive consumed pending-action.json on tool success. Immediately
# after that commit, a lockout was discovered: writing the next pa
# triggers PostToolUse, which archives the just-written pa, leaving
# pilot with no pa for the subsequent non-.tbd/ action.
#
# The carve-out: when the tool's target IS .tbd/pending-action.json
# itself, archive-pa returns noop instead of archiving. The pa-update
# stays in place.
#
# CONTRACT: pipes a JSON PostToolUse hook input describing a successful
# Edit whose tool_input.file_path is .tbd/pending-action.json. Asserts
# pa is NOT moved to archive and original remains.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d -t d052-self-archive.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/.tbd"

cat > "$TMP_DIR/.tbd/pending-action.json" <<'EOF'
{
  "version": 1,
  "id": "pa-test-self-archive-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Edit",
  "intent_str": "test fixture: pa that should NOT be archived (target IS pending-action.json)",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

cat > "$TMP_DIR/.tbd/session-state.json" <<'EOF'
{
  "version": 1,
  "session_id": "s-test-self-archive-001",
  "started_at": "2026-05-20T00:00:00Z",
  "mode": "paired"
}
EOF

# PostToolUse hook input: success=true (would normally archive)
# BUT tool_input.file_path is .tbd/pending-action.json itself —
# the self-archive carve-out should skip archiving.
HOOK_INPUT=$(cat <<EOF
{
  "tool_name": "Edit",
  "tool_input": {"file_path": "$TMP_DIR/.tbd/pending-action.json", "old_string": "x", "new_string": "y"},
  "tool_response": {"success": true},
  "cwd": "$TMP_DIR"
}
EOF
)

echo "$HOOK_INPUT" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

# Assertions: WITHOUT the carve-out, archive-pa would move pa to archive
# (this is what would happen and what we are testing AGAINST).
# WITH the carve-out, pa remains in place.
ARCHIVED="$TMP_DIR/.tbd/archive/s-test-self-archive-001/pa-test-self-archive-001.json"
ORIGINAL="$TMP_DIR/.tbd/pending-action.json"

if [ ! -f "$ARCHIVED" ] && [ -f "$ORIGINAL" ]; then
  echo "PASS: self-archive carve-out skipped archiving (target was pending-action.json)"
  echo "      pa remains in place: $ORIGINAL"
  exit 0
else
  echo "FAIL: expected pa NOT archived, original retained"
  [ -f "$ARCHIVED" ] && echo "      archive exists: YES (should NOT — carve-out failed)" || echo "      archive exists: no"
  [ -f "$ORIGINAL" ] && echo "      original exists: yes" || echo "      original exists: NO (was incorrectly archived)"
  exit 1
fi

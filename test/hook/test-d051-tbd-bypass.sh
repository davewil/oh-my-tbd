#!/usr/bin/env bash
# test/hook/test-d051-tbd-bypass.sh
#
# Verifies the .tbd/ orchestration substrate carve-out (D-051).
# See DESIGN-LOG.md D-051 for the rationale.
#
# Asserts that the veto-check hook allows Write/Edit/NotebookEdit calls
# targeting paths inside .tbd/* even when pending-action.tool declares
# a different tool. This eliminates the recursion gap where navigator
# or pilot writes to discipline substrate files (veto.json, dissent-
# log.jsonl, pending-action.json itself) are blocked by the very
# discipline operating on them.
#
# CONTRACT: pipes a JSON hook-input into `node bin/tbd.js hook veto-check`
# and asserts the JSON response contains permissionDecision=allow.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d -t d051-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Setup: fake project with .tbd/ containing a stale pending-action whose
# tool field is "Edit" (mismatched with the test Write call below). Without
# the D-051 carve-out, the hook would refuse the Write on tool mismatch.
mkdir -p "$TMP_DIR/.tbd"
cat > "$TMP_DIR/.tbd/pending-action.json" <<EOF
{
  "version": 1,
  "id": "pa-test-001",
  "proposed_at": "2026-05-20T00:00:00Z",
  "tool": "Edit",
  "intent_str": "test fixture: pending declares Edit to provoke mismatch",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test-001"
}
EOF

# Hook input: a Write call targeting .tbd/veto.json — the canonical
# navigator-write-its-own-veto case D-051 carves out.
HOOK_INPUT=$(cat <<EOF
{
  "tool_name": "Write",
  "tool_input": {"file_path": "$TMP_DIR/.tbd/veto.json", "content": "{}"},
  "cwd": "$TMP_DIR"
}
EOF
)

RESULT=$(echo "$HOOK_INPUT" | node "$REPO_ROOT/bin/tbd.js" hook veto-check)

if echo "$RESULT" | grep -q '"permissionDecision":"allow"'; then
  echo "PASS: D-051 carve-out allows Write to .tbd/ despite pending tool mismatch"
  echo "      hook response: $RESULT"
  exit 0
else
  echo "FAIL: expected permissionDecision=allow for Write to .tbd/*"
  echo "      got: $RESULT"
  exit 1
fi

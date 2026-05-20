#!/usr/bin/env bash
# test/hook/test-d052-archive-on-success.sh
#
# Verifies D-052 (soft variant per Q-034, ratified per D-053):
# on PostToolUse, the archive-pa subcommand moves the consumed
# .tbd/pending-action.json to .tbd/archive/<session_id>/pa-<id>.json
# and removes the original.
#
# FIXTURE PROVENANCE: the hook input below is a captured real CC
# PostToolUse Edit-success payload (sourced from intent-2026-05-20-008
# spike capture at /tmp/post-tooluse-payload.log), NOT a SCHEMAS.md
# idealised example. Per D-057, real CC PostToolUse payloads have no
# `tool_response.success` field — the field is absent, not just false.
# The session-4 fixture-honesty lesson generalised: tests must derive
# fixtures from captured platform payloads, not from doc examples.
#
# REACHABILITY: per D-058 (n=4 corpus from intent-2026-05-20-011 spike),
# CC PostToolUse fires only on tool success. There is no failure-case
# companion test because the failure-path code is provably unreachable
# in production. The prior failure test (test-d052-archive-on-failure.sh)
# was deleted alongside the predicate it depended on as part of
# intent-2026-05-20-013.
#
# CONTRACT: pipes the captured-real-shape JSON PostToolUse hook input
# into `node bin/tbd.js hook archive-pa` and asserts on the filesystem
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

# PostToolUse hook input: captured-real-shape Edit-success payload.
# Note the ABSENCE of `tool_response.success` (real CC never emits it)
# and the presence of the real Edit-tool response keys (filePath /
# oldString / newString / originalFile / structuredPatch / userModified /
# replaceAll). The full CC envelope (session_id, agent_type, hook_event_name,
# tool_use_id, etc.) is preserved verbatim from the captured payload —
# future code paths (e.g. action-trace) will read these fields, and
# pruning them now would re-introduce the same fixture dishonesty the
# session-4 lesson warned against.
#
# `originalFile` is truncated to a one-line placeholder because the real
# captured value is the entire pre-edit file content (multi-KB, unbounded)
# and archive-pa never reads that field. The schema-presence of the key is
# load-bearing for honesty; the exact content is not.
HOOK_INPUT=$(cat <<EOF
{
  "session_id": "c4bef4aa-4076-48ac-967c-e6835028aeb5",
  "transcript_path": "/dev/null/transcript-placeholder.jsonl",
  "cwd": "$TMP_DIR",
  "permission_mode": "default",
  "agent_type": "oh-my-tbd:pilot",
  "effort": {"level": "high"},
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "$TMP_DIR/some/output.txt",
    "old_string": "before",
    "new_string": "after",
    "replace_all": false
  },
  "tool_response": {
    "filePath": "$TMP_DIR/some/output.txt",
    "oldString": "before",
    "newString": "after",
    "originalFile": "<truncated for fixture; real captures contain full pre-edit file>",
    "structuredPatch": [],
    "userModified": false,
    "replaceAll": false
  },
  "tool_use_id": "toolu_test_d052_archive_on_success",
  "duration_ms": 8
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

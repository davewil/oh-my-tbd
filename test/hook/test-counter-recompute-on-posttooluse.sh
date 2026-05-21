#!/usr/bin/env bash
# test/hook/test-counter-recompute-on-posttooluse.sh
#
# Intent: intent-2026-05-21-004 (fix: wire session-state.json counter
# maintenance — derive counts.vetoes_raised / vetoes_lifted / overrides /
# archived_pas from dissent-log.jsonl + overrides.jsonl + archive/ on
# PostToolUse).
#
# Failing-first regression test (XP/tdd). Asserts that running the
# archive-pa PostToolUse handler re-derives counts.* in
# .tbd/session-state.json from on-disk sources.
#
# DERIVATION SOURCES (precision-correction over the intent text):
#   counts.vetoes_raised  ← count of '"event":"veto_raised"' lines in dissent-log.jsonl
#   counts.vetoes_lifted  ← count of '"event":"veto_lifted"' lines in dissent-log.jsonl
#   counts.overrides      ← line count of overrides.jsonl (each line is one override
#                           per SCHEMAS.md §5; absence => 0)
#   counts.archived_pas   ← file count under archive/<session_id>/pa-*.json
#                           (post-archive ordering: re-derivation runs AFTER pa is moved
#                           on success-path; so the newly-archived pa is counted)
#
# FIXTURE PROVENANCE: hook input is the captured-real-shape PostToolUse
# Edit-success payload (sourced from intent-2026-05-20-008 spike capture,
# mirroring test-d052-archive-on-success.sh per D-057 fixture-honesty).
# Per D-058 only success-path PostToolUse fires reliably in production,
# so no failure-companion case is needed.
#
# IDEMPOTENCE: per current-intent.json L21, re-derivation must be a
# pure function of dissent-log.jsonl + overrides.jsonl + archive/ —
# running twice with no new events must produce identical counts.
# This is the constraint that makes partial/failed runs self-heal.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d -t counter-recompute-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------- Setup: fake project with .tbd/ wired for re-derivation ----------

mkdir -p "$TMP_DIR/.tbd/archive/s-test-counter-001"

# session-state.json: counts all 0 — must move after PostToolUse.
cat > "$TMP_DIR/.tbd/session-state.json" <<'EOF'
{
  "version": 1,
  "session_id": "s-test-counter-001",
  "started_at": "2026-05-21T00:00:00Z",
  "mode": "paired",
  "counts": {
    "swaps": 0,
    "vetoes_raised": 0,
    "vetoes_lifted": 0,
    "vetoes_escalated": 0,
    "overrides": 0,
    "questions_asked": 0
  }
}
EOF

# dissent-log.jsonl: 2 veto_raised + 1 veto_lifted events.
# Other event types (veto_held, veto_sustained) are deliberately included
# to verify the predicate matches only the canonical {raised,lifted} strings.
cat > "$TMP_DIR/.tbd/dissent-log.jsonl" <<'EOF'
{"version":1,"ts":"2026-05-21T01:00:00Z","event":"veto_raised","veto_id":"v-test-001"}
{"version":1,"ts":"2026-05-21T01:05:00Z","event":"veto_lifted","veto_id":"v-test-001"}
{"version":1,"ts":"2026-05-21T01:10:00Z","event":"veto_raised","veto_id":"v-test-002"}
{"version":1,"ts":"2026-05-21T01:15:00Z","event":"veto_held","veto_id":"v-test-002"}
{"version":1,"ts":"2026-05-21T01:20:00Z","event":"veto_sustained","veto_id":"v-test-002"}
EOF

# overrides.jsonl: 2 lines (each is an override per SCHEMAS.md §5).
cat > "$TMP_DIR/.tbd/overrides.jsonl" <<'EOF'
{"id":"o-test-001","at":"2026-05-21T02:00:00Z","veto_overridden_ref":"v-test-002","reason_given":"hotfix","authorised_by":"human","session_id":"s-test-counter-001","action_permitted_ref":"pa-test-099"}
{"id":"o-test-002","at":"2026-05-21T02:30:00Z","veto_overridden_ref":"v-test-003","reason_given":"hotfix","authorised_by":"human","session_id":"s-test-counter-001","action_permitted_ref":"pa-test-100"}
EOF

# archive/<sid>/: 3 pre-existing archived pas.
for i in 001 002 003; do
  cat > "$TMP_DIR/.tbd/archive/s-test-counter-001/pa-existing-$i.json" <<EOF
{"version":1,"id":"pa-existing-$i","proposed_at":"2026-05-20T00:00:00Z","tool":"Edit","intent_str":"prior","diff_summary":{"files_changed":0,"lines_added":0,"lines_removed":0,"files":[]},"intent_ref":"intent-prior"}
EOF
done

# pending-action.json: will be consumed by the PostToolUse handler.
cat > "$TMP_DIR/.tbd/pending-action.json" <<'EOF'
{
  "version": 1,
  "id": "pa-test-counter-fresh",
  "proposed_at": "2026-05-21T03:00:00Z",
  "tool": "Edit",
  "intent_str": "test fixture pa — to be consumed on PostToolUse success",
  "diff_summary": {"files_changed": 0, "lines_added": 0, "lines_removed": 0, "files": []},
  "intent_ref": "intent-test"
}
EOF

# ---------- Captured-real-shape PostToolUse hook input ----------
# Same provenance as test-d052-archive-on-success.sh (D-057): real CC
# PostToolUse Edit-success envelope, no `tool_response.success` field,
# real Edit response keys preserved. `originalFile` truncated to a
# placeholder (archive-pa / recomputeCounts never read it).
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
    "originalFile": "<truncated for fixture>",
    "structuredPatch": [],
    "userModified": false,
    "replaceAll": false
  },
  "tool_use_id": "toolu_test_counter_recompute",
  "duration_ms": 8
}
EOF
)

# ---------- First fire: pa consumed + counts re-derived ----------

echo "$HOOK_INPUT" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

STATE_FILE="$TMP_DIR/.tbd/session-state.json"

# Use node to parse JSON portably — avoids jq dependency, mirrors how
# bin/tbd.js itself reads state. Each assertion isolates one counter so
# failures pinpoint the broken derivation source.
assert_count() {
  local field="$1"
  local expected="$2"
  local stage="$3"
  local actual
  actual=$(node -e "const s = require('$STATE_FILE'); process.stdout.write(String(s.counts && s.counts.$field));")
  if [ "$actual" != "$expected" ]; then
    echo "FAIL ($stage): expected counts.$field == $expected, got $actual"
    echo "       state file: $STATE_FILE"
    cat "$STATE_FILE"
    exit 1
  fi
}

assert_count vetoes_raised 2 "first fire"
assert_count vetoes_lifted 1 "first fire"
assert_count overrides     2 "first fire"
assert_count archived_pas  4 "first fire"   # 3 pre-existing + 1 just archived

# ---------- Second fire: idempotence (no new events, no new pa) ----------
# Re-derivation must be a pure function of the on-disk sources; with no
# new events, counts must be unchanged. (No new pa is written, so
# archive-pa's pa branch is a no-op; the counter branch still fires.)

echo "$HOOK_INPUT" | node "$REPO_ROOT/bin/tbd.js" hook archive-pa >/dev/null

assert_count vetoes_raised 2 "idempotence"
assert_count vetoes_lifted 1 "idempotence"
assert_count overrides     2 "idempotence"
assert_count archived_pas  4 "idempotence"

# ---------- Non-touched fields preserved ----------
# YAGNI guard: this fix must not silently rewrite swaps, vetoes_escalated,
# or questions_asked. They remain at their pre-fire values (0 in this fixture).

assert_count swaps              0 "non-touched"
assert_count vetoes_escalated   0 "non-touched"
assert_count questions_asked    0 "non-touched"

echo "PASS: counter re-derivation produces correct values from dissent-log + overrides.jsonl + archive/, and is idempotent"
exit 0

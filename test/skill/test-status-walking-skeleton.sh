#!/usr/bin/env bash
# test/skill/test-status-walking-skeleton.sh
#
# TDD-RED test for intent-2026-05-21-002 (feature: /tbd:status walking-skeleton).
# Asserts the structural contract of skills/status/SKILL.md.
#
# Because the skill is LLM-interpreted (no executable to run end-to-end), this
# test does NOT pipe a fixture .tbd/ into a runner and diff against expected
# output. Auto-assertion of dashboard rendering is a deferred bite — the
# walking-skeleton's whole job is to surface where this form breaks under real
# use (per NEXT-SESSION.md). The honest first test is structural: does the
# skill document what NEXT-SESSION.md priority-1 requires?
#
# At the bottom, this script echoes nine documented fixtures — one per row of
# the suggestion state-machine. These are scaffolding for human-graded
# dogfooding: place each .tbd/ state, invoke /tbd:status, eyeball the dashboard
# and the "Next:" line. They do NOT influence pass/fail.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/status/SKILL.md"

PASS=0
FAIL=0

assert_grep() {
  local needle="$1"
  local label="$2"
  if grep -qE "$needle" "$SKILL" 2>/dev/null; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (pattern: $needle)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Structural assertions on $SKILL ==="
echo

# 1. File exists at all
if [ -f "$SKILL" ]; then
  echo "  PASS  skills/status/SKILL.md exists"
  PASS=$((PASS + 1))
else
  echo "  FAIL  skills/status/SKILL.md does not exist (RED: pa-013 will land it)"
  FAIL=$((FAIL + 1))
  echo
  echo "=== Structural checks skipped — file absent ==="
  echo
  # Still fall through to fixture echo so the human-grading scaffolding is
  # always visible.
fi

# 2. YAML frontmatter
if [ -f "$SKILL" ]; then
  assert_grep '^---$'                                "frontmatter delimiter present"
  assert_grep '^description:'                        "frontmatter has description: field"

  # 3. References all 9 state-machine row states (using load-bearing fragments)
  assert_grep '`?\.tbd/`? +directory does not exist'                "row 1: no .tbd/ directory"
  assert_grep 'standing'                                            "row 2: standing veto"
  assert_grep 'pending-action\.json|pending action'                 "row 3: pending-action exists"
  assert_grep '[Nn]o current[- ]intent.*dirty|dirty.*[Nn]o current[- ]intent'  "row 4: no current-intent, dirty tree"
  assert_grep 'no current[- ]intent.*clean.*ahead|ahead of origin'  "row 5: clean, ahead of origin"
  assert_grep 'open.*clean.*no pending|no pending-action'           "row 6: intent open, clean, no pa"
  assert_grep 'open.*dirty|dirty.*open'                             "row 7: intent open, dirty tree"
  assert_grep 'closed.*clean|everything clean|all clean'            "row 8: everything clean, closed"
  assert_grep 'Unknown state|unknown state'                         "row 9: unknown-state fallback"

  # 4. <unknown> / <drifted> rule
  assert_grep '<unknown>'                                           "<unknown> sentinel documented"
  assert_grep '<drifted>'                                           "<drifted> sentinel documented"

  # 5. "Next:" line documented
  assert_grep '\*\*Next:\*\*|^Next:'                                "Next: line documented"
fi

echo
echo "=== Summary ==="
echo "  $PASS passed, $FAIL failed"
echo

# 9 fixture rows — documented for human-graded dogfooding
echo "=== Manual dogfood fixtures (informational, not asserted) ==="
echo
echo "Row 1 — No .tbd/ directory:"
echo "  Setup: rm -rf .tbd/ in a temp project"
echo "  Expect: dashboard surfaces 'no substrate'; Next: /tbd:init"
echo
echo "Row 2 — .tbd/veto.json with status: standing:"
echo "  Setup: write a fake veto.json with {\"status\":\"standing\",...}"
echo "  Expect: dashboard surfaces veto; Next: address veto or file dissent"
echo
echo "Row 3 — .tbd/pending-action.json exists, no standing veto:"
echo "  Setup: write a fresh pa, no veto.json"
echo "  Expect: dashboard surfaces pending pa; Next: invoke navigator"
echo
echo "Row 4 — No current-intent (or status=completed), working tree dirty:"
echo "  Setup: rm current-intent.json; touch foo.txt"
echo "  Expect: Next: /tbd:start <type> '<description>'"
echo
echo "Row 5 — No current-intent, clean tree, local ahead of origin:"
echo "  Setup: rm current-intent.json; commit then don't push"
echo "  Expect: Next: git push origin main"
echo
echo "Row 6 — Current-intent open, clean tree, no pending-action:"
echo "  Setup: current-intent.json status=open; no pa; clean tree"
echo "  Expect: Next: declare pa or close intent"
echo
echo "Row 7 — Current-intent open, dirty tree, no pending-action:"
echo "  Setup: current-intent.json status=open; touch foo.txt; no pa"
echo "  Expect: Next: declare pa for the changes"
echo
echo "Row 8 — Everything clean, intent closed, nothing ahead:"
echo "  Setup: current-intent.json status=completed; clean tree; in sync"
echo "  Expect: Next: /tbd:start next work-unit (or stop)"
echo
echo "Row 9 — Unknown state (none of above match):"
echo "  Setup: some pathological combination not enumerated above"
echo "  Expect: 'Unknown state — manual investigation needed' + state dump"
echo

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0

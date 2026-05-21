#!/usr/bin/env bash
# test/hook/test-s3-narrow-refuse-on-trunk.sh
#
# Pins the s3 narrow safety hook: refuse ONLY three chainsaw operations
# on trunk. Everything else is conversation, not refusal.
#
# Refuses (deny):
#   1. git push --force (and --force-with-lease) on trunk
#   2. git reset --hard <anything> when on trunk
#   3. git branch -D <trunk> (regardless of current branch)
#
# Permits (allow):
#   4. git push origin main (without --force) — normal trunk push
#   5. git reset --soft <ref> — soft reset preserves working tree
#   6. git branch -D some-feature — deleting a feature branch
#
# Trunk identified via .tbd/config.yaml trunk_branch override in this fixture.
#
# CONTRACT: pipes a JSON hook-input into `node bin/tbd.js hook safety-check`
# and asserts the JSON response contains permissionDecision=allow or =deny.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d -t s3-test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Fixture: .tbd/config.yaml declares the trunk branch explicitly so detection
# works without a configured remote.
mkdir -p "$TMP_DIR/.tbd"
cat > "$TMP_DIR/.tbd/config.yaml" <<'EOF'
trunk_branch: main
EOF

PASS_COUNT=0
FAIL_COUNT=0

# Helper: run one case. Args: case_name, expected (allow|deny), bash_command
run_case() {
  local case_name="$1"
  local expected="$2"
  local bash_command="$3"

  local hook_input
  hook_input=$(cat <<EOF
{
  "tool_name": "Bash",
  "tool_input": {"command": "$bash_command"},
  "cwd": "$TMP_DIR"
}
EOF
)

  local result
  result=$(echo "$hook_input" | node "$REPO_ROOT/bin/tbd.js" hook safety-check 2>&1 || true)

  if echo "$result" | grep -q "\"permissionDecision\":\"$expected\""; then
    echo "  PASS: $case_name (expected $expected)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $case_name (expected $expected)"
    echo "        command: $bash_command"
    echo "        got: $result"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "s3 narrow-refuse-on-trunk:"

# === Refuses ===
run_case "case 1: git push --force origin main refused" \
  "deny" \
  "git push --force origin main"

run_case "case 1b: git push --force-with-lease origin main refused" \
  "deny" \
  "git push --force-with-lease origin main"

run_case "case 1c: git push -f origin main refused" \
  "deny" \
  "git push -f origin main"

run_case "case 2: git reset --hard HEAD~1 refused (on trunk)" \
  "deny" \
  "git reset --hard HEAD~1"

run_case "case 3: git branch -D main refused" \
  "deny" \
  "git branch -D main"

run_case "case 3b: git branch --delete --force main refused" \
  "deny" \
  "git branch --delete --force main"

# === Permits ===
run_case "case 4: git push origin main (no --force) permitted" \
  "allow" \
  "git push origin main"

run_case "case 5: git reset --soft HEAD~1 permitted" \
  "allow" \
  "git reset --soft HEAD~1"

run_case "case 6: git branch -D some-feature permitted" \
  "allow" \
  "git branch -D some-feature"

# Non-chainsaw Bash should pass straight through.
run_case "case 7: ls (non-state-changing) permitted" \
  "allow" \
  "ls"

# Force-push to non-trunk branch should be permitted (personal feature work).
run_case "case 8: git push --force origin some-feature permitted" \
  "allow" \
  "git push --force origin some-feature"

echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "PASS: all $PASS_COUNT cases"
  exit 0
else
  echo "FAIL: $FAIL_COUNT of $((PASS_COUNT + FAIL_COUNT)) cases"
  exit 1
fi

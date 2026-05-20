# Session 4 — 2026-05-20 — intent-008 spike → D-057 + Q-036/037/038 opened

**Intents:** intent-008 (chore spike, no commit) → intent-009 (docs)
**Commits:** `515f2c9` (1 commit; spike was commit-less per design)
**Outcome headline:** Action-trace work deferred after instrumentation spike reveals archive-pa silent-broken in production since D-052 landed (no `tool_response.success` field in real CC payloads → predicate noop'd universally → `.tbd/archive/` never created on disk). Six findings landed for one Edit+two Bash+one Read. n=1 D-058 attempt downgraded to Q-038 by navigator pa-057 veto — evidence-proportionality lesson crystallizes.

---

## Commit chain

| Commit | What |
|---|---|
| `515f2c9` | intent-009 docs ratifying intent-008 spike findings — D-057 (archive-pa silent-broken since D-052 landed), Q-036 (PostToolUseFailure subscription), Q-037 (session_id namespace), Q-038 (does PostToolUse fire on failure? n=1); NEXT-SESSION priority queue restructured to 7 items. **No prior session-4 commit** — intent-008 was a commit-less instrumentation spike per design |

## Session 4 progress (2026-05-20, intent-008 spike no-commit + intent-009 docs commit `515f2c9`)

**Goal:** start work on session-3 priority 2 (action-trace.jsonl population). Discovered mid-flight that priority 2 presupposes a working substrate, then discovered the substrate was silently broken.

**Outcome:** action-trace work deferred to intent-012 (newly-priority 3). Real session-4 deliverables: intent-008 spike (no commit, per design) capturing real CC PostToolUse payload shapes to `/tmp/post-tooluse-payload.log`; intent-009 docs commit (this one) ratifying D-057 + Q-036/Q-037/Q-038 and restructuring priority queue. Net: an honest substrate-state model now exists, fix-first (intent-010 fixture replacement) before any new feature builds on top. `bin/tbd.js` clean (HEAD baseline restored; git diff empty post-spike-revert).

### Three lessons worth carrying forward

- **Empirical capture has higher ROI than its sponsor question.** The intent-008 spike was scoped to answer one binary design question (PostToolUse handler ordering for action-trace + archive-pa). Its first capture revealed `tool_response.success` absent in real payloads — which made the sponsor question moot (archive-pa wasn't even successfully firing its predicate, so handler-ordering was a separate problem from the load-bearing one). Six concrete findings landed for the cost of one Edit + two Bash + one Read: D-057 + Q-036 + Q-037 + Q-038 + per-tool field-shape capture + agent_type-event-symmetry confirmation. **Pattern:** spike instrumentation should capture the FULL payload, not just the predicate of interest. The bonus findings often reshape the priority queue more than the sponsor finding does. Generalises the session-3 "instrument once, learn many" lesson — extend it to "the cheapest broad capture beats the targeted one."

- **The discipline catches my overclaim — and that's the point.** Navigator vetoed pa-057 on LEAN/amplify-learning grounds: I was promoting a single observation (one failed Bash producing no PostToolUse entry) to a categorical D-058 ("PostToolUse fires only on success") and using it to justify removing the success predicate in intent-010. The navigator's blind-to-conversation context is exactly the resistance to my own synthesis-momentum that the pair architecture is supposed to provide. In long pilot threads I accumulate narrative confidence across many turns; the navigator sees only PA + diff + principles + dispositive artefact, and asks "is the evidence sufficient for the claim?" — and on D-058 it wasn't. Lift path 2 (downgrade D-058 to Q-038, narrow intent-010 to fixture-replacement only) was the more honest resolution; defence-in-depth code stays until a broader corpus probe resolves Q-038. **Pattern:** when the pilot's synthesis spans many findings and the conclusion lands a load-bearing decision, the navigator's veto is the canonical check on whether the evidence supports the conclusion at the *granularity of that decision*.

- **Test-fixture honesty is the load-bearing missing test.** D-052's `test-d052-archive-on-success.sh` has been passing for months against a synthetic fixture (`tool_response: {"success": true}`) designed from SCHEMAS.md §5's idealised example. Real CC payloads have no `success` field at all. Production archive-pa noops on every real invocation; `.tbd/archive/` has never been created on disk. The session-2 "by-inspection mutation analysis" lesson would NOT have caught this — mutation analysis checks the test detects code-level mutations, but it can't detect that the fixture itself models a scenario the runtime never produces. **Pattern:** every hook test should derive its fixture from a captured real-platform payload, not from a schema doc's idealised example. Possible project convention: add a `test/fixtures/captured/` directory holding named real-payload JSON files committed alongside the tests that consume them; CI could re-capture and diff to detect drift. Combine with the session-3 "instrument once, learn many" — the same instrumentation that answers the immediate question also produces the fixtures for the next test generation.

### Substrate observations for next session

- `dissent-log.jsonl` grew from ~26 entries to ~32 entries this session (intent-008 spike + intent-009 cycles, including a `veto_raised`/`veto_lifted` pair for pa-057). **The pa-057 entry is the project's first dogfood-surfaced sustained-then-lifted veto under D-053 calibration** — navigator held until the pilot revised the claim, not the prose.
- `current-intent.json` ended at intent-009 (this docs commit). Intent chain across session 4: 008 (chore spike, no commit), 009 (docs, this commit).
- `bin/tbd.js` unchanged from session-3 baseline (4b93fda). `bin/tbd.js:199` predicate retained pending Q-038. Three carve-outs in `runVetoCheck` from session 3 still in place (read-only Bash, D-056 navigator-agent, D-051 `.tbd/` substrate).
- `/tmp/post-tooluse-payload.log` holds 2 captured real-CC payloads (one Edit success, one Bash success) — sufficient for intent-010 fixture replacement; intent-011 will capture more (failures across tools). NOT committed; if /tmp is cleared between sessions, re-capture via the same instrumentation pattern.
- `pilot-responses.jsonl` exists for the first time (created at pa-057 dispute round) with two narrow-scope responses; pattern available for future veto disputes.
- Spike findings count across all sessions: session-3 spike found 1 thing (agent_type field); session-4 spike found 6 things from the same instrumentation shape. Marginal cost of "capture more fields" was zero; payoff was 6×.

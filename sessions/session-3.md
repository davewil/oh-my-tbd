# Session 3 — 2026-05-20 — Q-035 / D-056 navigator-agent-type carve-out in runVetoCheck

**Intents:** intent-005 (chore spike, no commit) → intent-006 (feat, commit) → intent-007 (docs)
**Commits:** `360d1e3` → `4b93fda` (2 commits)
**Outcome headline:** Q-035 reconciliation lands as D-056 — `agent_type === 'oh-my-tbd:navigator'` bypass in `runVetoCheck`; dogfood loop closes end-to-end (navigator's own commit-stage review writes dissent-log directly under the new carve-out); 5-minute spike pattern crystallizes.

---

## Commit chain

| Commit | What |
|---|---|
| `360d1e3` | Q-035 / D-056 — navigator-agent-type carve-out in veto-check; `agent_type === 'oh-my-tbd:navigator'` bypasses pa-tool-match. TDD-RED→GREEN test, all five hook tests pass, navigator's own commit-stage review wrote dissent-log directly (first navigator write under carve-out) |
| `4b93fda` | Docs close-out for session 3 — D-056 ratified in DESIGN-LOG, Q-035 marked resolved, NEXT-SESSION priority queue updated to 4 items |

## Session 3 progress (2026-05-20, commits `c78c3f2 → 360d1e3` chain)

**Goal:** close priority 1 from session-2 NEXT-SESSION — Q-035 reconciliation.

**Outcome:** landed and pushed (`360d1e3`). D-056 ratified: navigator-agent-type carve-out in `runVetoCheck` keyed on `hookInput.agent_type === 'oh-my-tbd:navigator'`. Dogfood loop closed end-to-end: the navigator's own commit-stage review on the very commit landing the carve-out was the first navigator to write `.tbd/dissent-log.jsonl` directly.

### Three lessons worth carrying forward

- **The 5-minute spike pattern is gold for binary design questions.** Q-035 had three candidate fixes (hook-layer detection vs CLI helpers vs doc-reframe). The advisor flagged that the choice hinged on whether CC's hook payload includes an agent identifier — empirically unknown. Three lines of throwaway instrumentation (`appendFileSync` of stdin buffer to `/tmp`) + one navigator probe + one minute of inspection revealed `agent_type='oh-my-tbd:pilot'` vs `agent_type='oh-my-tbd:navigator'`. Without that data, I would have been weighing the wrong trade-offs. **Pattern:** when a design choice hinges on undocumented platform behaviour, the cheapest experiment that reveals the truth wins over the cleverest analysis.

- **The fix verified itself in production via dogfood.** Pre-carve-out: navigator's commit-stage review of pa-046 was refused on Bash, pilot trace-closed (Q-035 manifestation #7). Post-carve-out: navigator's commit-stage review of pa-048 wrote the dissent-log directly via `bin/tbd.js`'s newly-permissive predicate. Same review pattern, different substrate semantics — and the navigator's own action was the regression evidence. **Lesson:** when fixing a substrate-orchestration bug, the dogfood-immediately property is its own integration test.

- **Empirical capture revealed more than just `agent_type`.** The same instrumentation showed `session_id`, `tool_use_id`, `transcript_path`, `permission_mode`, `effort`, `hook_event_name`, `duration_ms` in the CC payload. Useful future leverage: priority 2 (action-trace.jsonl) can use `session_id` for deterministic per-session tracing without pilot/navigator counter-maintenance. **Lesson:** instrument once, learn many; the capture file is worth more than the single decision that motivated it.

### Substrate observations for next session

- `dissent-log.jsonl` grew from 22 to ~26 entries this session (pa-040 instrumentation lift, pa-044 RED-test lift, pa-046 GREEN-impl lift, pa-048 commit-stage lift). **pa-048 lift was written by the navigator directly** — historical first.
- `current-intent.json` ended at intent-007 (this docs close-out). Intent chain across session: 005 (chore spike, no commit), 006 (feat, commit 360d1e3), 007 (docs, this commit).
- Trunk advanced two commits (`c78c3f2 → 95bff0e → 360d1e3` and the docs commit landing this update), no divergence.
- `bin/tbd.js` now has three carve-outs in `runVetoCheck`: (1) read-only Bash (line 65), (2) D-056 navigator-agent (line 69), (3) D-051 `.tbd/` substrate (line 85). Order is significant — each is an early-return.
- Q-035 manifestation count across all sessions: 7+ refusals before D-056. After D-056: zero (verified via pa-048 navigator success).

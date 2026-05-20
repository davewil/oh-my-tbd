# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-20 session-3 (Q-035 closed via D-056 navigator-agent-type carve-out; priority 1 done)
- **Trunk state:** main at `360d1e3`, pushed to origin (github.com/davewil/oh-my-tbd)
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## Where we are

**Walking-skeleton + D-052 + self-archive fix complete.** Commit sequence (after `030cb17 Bootstrap`):

| Commit | What |
|---|---|
| `e082866` | D-051 orchestration substrate carve-out (Write/Edit/NotebookEdit) + CLI-contract test |
| `d790f61` | DESIGN-LOG: log D-051/D-052/D-053 + Q-033/Q-034 |
| `e1a56e0` | Full pilot and navigator system prompts (Opus navigator) |
| `0caaa72` | Wire veto-check hook into PreToolUse |
| `ab56f47` | Skill specs: /oh-my-tbd:start, /oh-my-tbd:override |
| `53e9efe` | TBD/XP/LEAN principles checklist (navigator rubric source) |
| `34363b0` | Activate pilot as main thread via settings.json (D-049) |
| `4737da5` | Update NEXT-SESSION.md post-walking-skeleton |
| `736fe5a` | D-052 soft consumption tracking (Q-034) — archive-pa on PostToolUse success |
| `5443f48` | Self-archive carve-out fix in archive-pa (`runArchivePa` skips when target is `.tbd/pending-action.json`) |
| `c78c3f2` | **(session 2)** D-052 archive-on-failure negative-case test (`success=false` + `success-absent` fixtures) — pins predicate at `bin/tbd.js:191` against removal, inversion, and `!==true → ===false` softening mutations |
| `95bff0e` | **(session 2)** NEXT-SESSION.md session-2 close-out — priority 2 done, queue renumbered, three lessons captured |
| `360d1e3` | **(session 3)** Q-035 / D-056 — navigator-agent-type carve-out in veto-check; `agent_type === 'oh-my-tbd:navigator'` bypasses pa-tool-match. TDD-RED→GREEN test, all five hook tests pass, navigator's own commit-stage review wrote dissent-log directly (first navigator write under carve-out) |

**Net result:** anyone enabling the plugin (`claude --plugin-dir .` or installed) gets the full discipline: pilot is the default main agent, navigator is invocable as `oh-my-tbd:navigator`, the veto-check hook fires on every state-changing tool call, `.tbd/` orchestration substrate is freely writable per D-051, principles checklist is loaded as the navigator's rubric source.

**Decisions added this session:** D-051 (`.tbd/` carve-out — implemented), D-052 (consumption tracking — deferred), D-053 (baseline-not-doctrine calibration — ratified).

**Open questions opened this session:** Q-033 (advisory pa at hook layer — D-054 candidate), Q-034 (soften consumption tracking — D-055 candidate), Q-035 (subagent tool calls bypass PreToolUse hook — discovered empirically).

---

## What to do next (priority order — updated post-session-3)

### 1. Implement Bash carve-out for D-051 (carefully)
**Files:** `bin/tbd.js`, `test/hook/`
**References:** D-051 deferred-Bash work; navigator's pa-004 review surfaced the simple-design concern. **Session 3 update:** D-056's navigator-agent-type carve-out reduces the pressure on this — the navigator (the main `.tbd/`-Bash caller) is now bypassed cleanly. Remaining motivation: pilot's read-only-with-redirect Bash (e.g. `cat foo >> .tbd/log.jsonl`) is still refused by `isReadOnlyBash`. Less urgent than it was post-session-2.
**Approach:** the regex-over-command-text approach has false-positive risk. Better: extract `>` / `>>` redirect targets from the command text, check if the redirect destination is inside `.tbd/`. Still heuristic but more precise. TDD-honest: land failing tests covering both true positives (`echo X > .tbd/foo`) and true negatives (`echo ".tbd/ string" >> CHANGELOG.md`).

### 2. action-trace.jsonl population
**Files:** `bin/tbd.js` (post-allow path)
**Reference:** D-018, COMPONENTS.md
**Approach:** when veto-check returns `allow`, also append a single line to `.tbd/action-trace.jsonl` capturing tool, redacted args, decision, timestamp. Q-029 (secret-redaction) is the open design question here. **Session 3 unlock:** the empirical capture also confirmed `session_id` is in the hook payload — useful for binding trace entries to sessions deterministically.

### 3. session-state.json counter maintenance
**Files:** `bin/tbd.js`, possibly skills' SKILL.md content for orchestration
**Reference:** the navigator surfaced this drift across multiple session reviews (`vetoes_lifted` stayed at 0 while dissent log accumulated). Either pilot bumps counters, navigator bumps counters, or the hook bumps counters on certain events.

### 4. current-intent.json cleanup convention
**Reference:** the navigator surfaced repeatedly that current-intent.json drifted from the actual work as batches progressed. Conventions to decide: when to re-declare, when to close out (delete? archive? mark complete?), how intent transitions propagate to pa. Session 2+3 pattern: each work-unit re-declared (intent-003 test, intent-004 docs, intent-005 chore spike, intent-006 feat, intent-007 docs) and closed with `completion_summary` field. Worked cleanly but is convention-by-precedent rather than codified.

### Closed in prior sessions
- ~~Add negative-case test for D-052 (success=false → no archive)~~ — DONE in `c78c3f2` (session 2)
- ~~Reconcile Q-035 — subagent tool calls and PreToolUse hooks~~ — DONE in `360d1e3` (session 3) — see D-056

---

## Open decisions to revisit during build

- **Q-002** (per-language non-interaction adapters) — needed when L2 reachability check lands
- **Q-019** (refactor behaviour-preservation check) — needed when refactor commit category is implemented
- **Q-029** (secret-redaction patterns in action-trace) — needed alongside #4 above
- **Q-030** (schema migration policy on `version:` bump) — needed at first version bump

---

## Files to read on resume (~5-10 minutes)

1. `README.md` — orient
2. This file (`NEXT-SESSION.md`)
3. `DESIGN-LOG.md` § Pinned decisions — recent entries are D-046 → D-053
4. `DESIGN-LOG.md` § Open questions — recent entries Q-028 → Q-034 (Q-035 not yet logged here; in dissent log only)
5. `.tbd/dissent-log.jsonl` — the empirical record from session 1
6. `COMPONENTS.md` § Walking skeleton — what's now done
7. `SCHEMAS.md` § Veto.json + § State machine — load-bearing artefacts

---

## Quick-resume commands

```bash
cd /Volumes/Personal/Users/davidwilliams/dev/trunk/
git log --oneline -10            # see the walking-skeleton commits
git pull origin main              # sync if anything landed remotely
node ./bin/tbd.js version         # smoke-test the CLI
bash ./test/hook/test-d051-tbd-bypass.sh   # smoke-test the carve-out (should PASS)
claude --plugin-dir .             # load the plugin in dev mode — pilot becomes default main agent
```

---

## Session-1 lessons worth carrying forward

- **D-051+D-052 friction was real but transient.** Once D-051 landed in batch 0, the per-batch ceremony collapsed from ~30 min to ~3 min per commit.
- **D-053 calibration changed the navigator's behaviour mid-session.** Same agent, same prompt, but the rubric application softened on procedural drift while staying firm on substantive risk.
- **The discipline catches real issues.** pa-004 TDD veto prevented untested production code from shipping. The carve-out fix is itself the canonical example of "fix it properly first, then resume."
- **The navigator self-disclosed a Bash discipline-break** (pa-018) — Q-035 emerged from that. The agent prompt's anti-bypass language held up under stress.
- **Don't add ceremony for low-risk work.** Per D-053, the `git push` after the walking skeleton landed needed no navigator review. Process serves people.
- **D-052 self-archive lockout** (session 1 close-out): writing pa to disk triggered PostToolUse → archive-pa → removed the just-written pa → blocked subsequent non-`.tbd/` actions. Fixed by adding self-archive carve-out to runArchivePa. Recovery used a deliberate bootstrap (pa-without-id exploits the graceful no-op branch). **Future: design "discipline emergency exit" patterns** (Q-036 candidate) so substrate lockouts have a clean recovery path beyond exploiting graceful-no-op branches.

## How session 1 ended (so resume reads cleanly)

The session closed with the walking-skeleton + D-052 + self-archive fix all landed and pushed. The discipline is self-bootstrapping AND self-correcting. The substrate state on disk:

- `.tbd/current-intent.json` — intent-002 marked `status: completed` (D-052 work unit). Next session should `/oh-my-tbd:start` a fresh intent before any work.
- `.tbd/pending-action.json` — whatever pa was active at the final commit. After that commit's PostToolUse, archive-pa fires; with the self-archive fix in place, only non-pending-action targets get archived, so the final commit's pa (Bash) gets archived normally. State on resume: pending-action.json may be absent (cleanly consumed).
- `.tbd/dissent-log.jsonl` — full audit trail of every veto raised/lifted across session 1. Useful reading for understanding the calibration evolution.
- `.tbd/archive/s-2026-05-20-001/` — all consumed pa's from session 1 (audit trail).
- `.tbd/session-state.json` — counter drift noted (vetoes_lifted=0 despite ~10 lift events). Cleanup is priority 4 (post-renumbering).

To resume safely:

1. Read `NEXT-SESSION.md` (this file) and `DESIGN-LOG.md` § Open questions (recent Q-033 → Q-035, plus possibly Q-036 if added).
2. Run `bash test/hook/test-d051-tbd-bypass.sh` and `bash test/hook/test-d052-archive-on-success.sh` and `bash test/hook/test-d052-archive-on-failure.sh` and `bash test/hook/test-d052-self-archive-skip.sh` — all four should PASS. Sanity check.
3. Run `/oh-my-tbd:start <type> <description>` to declare a fresh intent for whatever you're tackling.
4. Pick a priority from "What to do next" and proceed via normal pilot loop.

---

## Session 2 progress (2026-05-20, single commit `c78c3f2`)

**Goal:** close priority 2 from session-1 NEXT-SESSION — D-052 archive-on-failure negative-case test.

**Outcome:** landed. One file (`test/hook/test-d052-archive-on-failure.sh`, 103 lines), two fixtures (`success=false` + `success-absent`), all four hook tests PASS, pushed to origin. Total work-unit: ~3 commits' worth of pilot/navigator cycles compressed into one ship.

### Three lessons worth carrying forward

- **By-inspection mutation analysis caught an overclaimed docstring mid-batch.** My first version (pa-031) had a docstring claiming the test catches the `!==true → ===false` mutation. When I sat down to verify by case-by-case predicate analysis, I found `success=false` alone does NOT catch that mutation (both predicates noop for `false`). The fix was extending the test with an absent-success fixture (`tool_response: {}`) which DOES kill the mutant. **Lesson:** characterization tests need a brief manual mutation-table check before commit; "PASS against current code" is not evidence the test guards what its comment claims. The cost of the check was minutes; the cost of a silent regression hole would have been a future bug.

- **Q-035 (navigator Bash refused at `.tbd/`) manifested 3 times in this single batch.** Refused on pa-031/033/036 navigator reviews; allowed once on pa-034 vicinity. Each refusal cost ~30 sec of pilot trace-close bookkeeping (appending the navigator's veto_lifted entry to `dissent-log.jsonl` manually). The friction compounds linearly with batch count. Priority 1 (Q-035 reconciliation) is now the clear next move on cost-benefit: tightening the navigator's tool surface or extending the D-051 carve-out would eliminate this entirely.

- **The hook caught a tool-mechanic switch mid-batch.** I declared `tool: Edit` in pa-033 (incremental extension), navigator cleared, but my actual implementation grew into a structural rewrite via Write. The hook refused the Write because pa still said Edit. I had to declare pa-034 (Write) before proceeding. Crucially: the *substantive* content didn't change between pa-033 and pa-034 — only the tool mechanic. Per D-053, I proceeded without re-invoking the navigator for the tool-mechanic-only change. **Lesson:** the hook's `pa-tool === actual-tool` invariant is robust to "I'll just slip this through" reasoning even when intent feels unchanged. The invariant is mechanical and cheap; respect it.

### Substrate observations for next session

- `.tbd/archive/s-2026-05-20-001/` continues to hold session-1 pa archives; session-2 PostToolUse archives may have been written under same or distinct session_id (verify via `ls .tbd/archive/`).
- `dissent-log.jsonl` grew from 19 to 22 entries this session (three veto_lifted events for pa-031/033/036).
- `current-intent.json` ended at intent-004 (docs, this NEXT-SESSION.md update). Next session should `/oh-my-tbd:start` fresh.
- Trunk advanced one commit (`5443f48 → c78c3f2`), no divergence.

---

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

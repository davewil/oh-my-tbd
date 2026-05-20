# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-20 session-5 (intent-012 ratified intent-011 dual-probe spike findings: D-058 pinned [Q-038 resolved — PostToolUse fires only on success, n=4 corpus]; D-059 pinned [Q-036 resolved — PostToolUseFailure is a distinct CC event]; Q-039 + Q-040 opened; intent-010 scope broadened to bundle fixture-replacement + predicate-drop in one commit)
- **Trunk state:** main at `b6a37b6` (DESIGN-LOG ratification, session-5 commit 1) with this NEXT-SESSION.md update landing as session-5 commit 2 immediately after — both pushed to origin (github.com/davewil/oh-my-tbd); reader can `git log -12` from session-5 commit 2 for the full chain back to session-4's `515f2c9`
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## Where we are

**Walking-skeleton + D-056 + D-057/D-058/D-059 ratification all landed; substrate-state model is now honest end-to-end on CC's event-firing semantics; intent-010 fixture+predicate-drop fix is the immediate next work-unit (now bundled into one commit thanks to Q-038 resolution).** Commit sequence (after `030cb17 Bootstrap`):

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
| `4b93fda` | **(session 3)** Docs close-out for session 3 — D-056 ratified in DESIGN-LOG, Q-035 marked resolved, NEXT-SESSION priority queue updated to 4 items |
| `515f2c9` | **(session 4)** intent-009 docs ratifying intent-008 spike findings — D-057 (archive-pa silent-broken since D-052 landed), Q-036 (PostToolUseFailure subscription), Q-037 (session_id namespace), Q-038 (does PostToolUse fire on failure? n=1); NEXT-SESSION priority queue restructured to 7 items. **No prior session-4 commit** — intent-008 was a commit-less instrumentation spike per design |
| `b6a37b6` | **(session 5)** intent-012 part 1 — DESIGN-LOG.md ratification of intent-011 spike findings: D-058 (Q-038 resolved, PostToolUse fires only on success, n=4 corpus across Edit/Write/Bash + 2 Bash failure modes), D-059 (Q-036 resolved, PostToolUseFailure is a distinct CC event), Q-036 + Q-038 moved to resolved table, Q-039 (mid-session hooks.json edits don't reload until session-restart) + Q-040 (Edit-failure PostToolUseFailure variant unknown) opened. Intent-011 itself was a commit-less dual-probe spike per design (intent-005/008 precedent). |
| `<this commit>` | **(session 5)** intent-012 part 2 — NEXT-SESSION.md restructure: header pointer updated, commit table extended, priority queue restructured (intent-010 now broadens to fixture + predicate-drop in one commit; new priority 7 = intent-011-follow-on for Q-039/Q-040), open-decisions section reconciled, Session-5 progress section appended. Per-file-per-commit split (vs bundling DESIGN-LOG.md + NEXT-SESSION.md in one commit) chosen per pa-073 navigator first-remedy — disambiguates the cumulative-vs-per-pa-delta diff_summary convention. |

**Net result:** the discipline machinery's CC-event-firing assumptions are now empirically grounded end-to-end. Session-4 established that real CC PostToolUse payloads have no `success` field (D-057); session-5 added that CC's PostToolUse simply doesn't fire on tool failure at all (D-058, n=4 corpus across 3 tool classes) and that the failure side is served by a distinct `PostToolUseFailure` event subscribers can register for (D-059). Consequence: archive-pa's `tool_response.success !== true` predicate is provably unreachable on failure paths and can be dropped in the same commit as intent-010's fixture-replacement (one fewer "defence in depth" branch the test corpus has to characterise). `.tbd/archive/` still doesn't exist on disk pending intent-010's actual landing. Plugin still wires correctly (pilot is default main agent; navigator invocable; veto-check fires; D-051/D-056 carve-outs honoured); intent-010 (now bundled feat) is the unblocked next work-unit.

**Decisions added this session:** D-058 (Q-038 resolved — CC `PostToolUse` fires only on tool success; n=4 corpus across Edit/Write/Bash with 2 distinct Bash failure modes via intent-011 dual-probe spike; unblocks intent-010's predicate-drop bundle). D-059 (Q-036 resolved — `PostToolUseFailure` is a distinct CC event subscribers can register for; confirmed at OMC-reminder layer n=3 for Write+Bash failures; Edit-failure case ambiguous → Q-040; mid-session subscription reload mechanism unknown → Q-039). Session-5 dogfood note: where session-4 attempted D-058 and got downgraded to Q-038 on n=1 evidence (pa-057 sustained-then-lifted veto), session-5's n=4 corpus cleared the same navigator's bar for pinning. The calibration is "evidence proportional to claim weight," not "always downgrade behavioural observations."

**Open questions opened this session:** Q-039 (CC loads `hooks.json` at session-start; mid-session matcher additions don't take effect until session restart — empirically confirmed by intent-011 probe-2 PostToolUseFailure matcher being on-disk but never invoked; operationally important for action-trace impl). Q-040 (Edit-failure variant of D-059 — Edit failure produced no OMC-reminder layer `PostToolUseFailure:Edit` despite confirmed failure; unclear if event-not-fired or fired-but-omitted-from-reminder-layer; gated on Q-039 for fresh-session matcher test).

---

## What to do next (priority order — updated post-session-5)

### 1. Replace synthetic D-052 test fixture AND drop the `bin/tbd.js:199` success predicate in one commit (intent-010, BROADENED)
**Files:** `test/hook/test-d052-archive-on-success.sh`, `test/hook/test-d052-archive-on-failure.sh`, `bin/tbd.js` (predicate at line 199 — n.b. line may have shifted by other carve-out edits, search rather than hard-code).
**References:** D-057, D-058. Session-4 had scoped intent-010 to fixture-replacement only because Q-038 was n=1. Session-5's intent-011 spike resolved Q-038 (n=4 corpus, D-058): CC PostToolUse fires only on tool success, so the predicate at `bin/tbd.js:199` is provably never invoked on failure paths and can be dropped without functional change. Both changes belong in one commit because the test-fixture swap forces the predicate behaviour question, and answering it with predicate-drop is the honest single-step resolution.
**Approach (Outside-In TDD):** (a) re-capture a real-CC PostToolUse Edit payload via the established TEMP appendFileSync pattern (one Edit triggers it; /tmp/post-tooluse-payload.log is volatile across sessions); (b) swap the synthetic fixture (`tool_response: {"success": true}`) for the real-shape payload in `test-d052-archive-on-success.sh`; (c) confirm test FAILS (RED) against current predicate-retained `bin/tbd.js` — proves fixture and predicate are now in conversation; (d) drop the `tool_response.success !== true` early-return at `bin/tbd.js:199`; (e) confirm test PASSES (GREEN) and existing `test-d052-archive-on-failure.sh` still passes (per D-058, failure payloads never reach PostToolUse so the failure-test now relies on CC's event-firing semantics instead of our predicate — bookmark this as a small fixture-honesty TODO if test-d052-archive-on-failure.sh's fixture also uses synthetic `success: false` shape); (f) run all hook tests; (g) commit. Per `principles/principles.md`/TDD, RED-before-GREEN is required because this is production-code change in a `feat`-shaped work-unit.

### 2. action-trace.jsonl population (intent-013, was priority 3)
**Files:** `bin/tbd.js` (PostToolUse path)
**Reference:** D-018, COMPONENTS.md, plus session-4 design-fork resolutions from advisor synthesis.
**Approach:** when veto-check returns allow AND PostToolUse fires (i.e. tool succeeded per current understanding pending Q-038), append a single line to `.tbd/action-trace.jsonl` capturing tool, per-tool args (`file_path` for Edit/Write, `command_redacted` via existing `redact()` for Bash), `pending_action_ref` (read from pa file before archive-pa consumes it — see handler-ordering question in original advisor synthesis), `session_id`, `tool_use_id`, `agent_type`, timestamp, decision. Coverage includes carve-out paths (D-051 substrate writes, D-056 navigator actions) with `pending_action_ref: null` flagging them — gating on "pa existed" loses visibility into exactly the carve-out cases the discipline lets through. Q-025 (rotation) deferred: add TODO comment near append site, real growth data after a few sessions decides threshold.

### 3. TS migration kickoff (per D-038, was priority 4)
**Files:** `src/` (currently empty placeholder), `package.json` (currently absent), `bin/` (compiled output)
**References:** D-038 pinned; user surfaced in session 4 that typed `HookInput`/`ToolResponse` against real CC payload shapes (captured for success cases in `/tmp/post-tooluse-payload.log`, and now corroborated for failure-event shapes via intent-011 spike) would have prevented D-057 at compile time. Walking-skeleton JS was bootstrap simplicity; substrate semantics are now honest enough to be worth typing.
**Approach:** stand up `tsc` build chain, output to `bin/`. Define `HookInput` / `ToolResponse` / `PendingAction` / `Veto` / `SessionState` types from captured real payloads (not from SCHEMAS.md idealised examples). Port `bin/tbd.js` line-by-line preserving behaviour — every hook test must still pass. Per D-053, a chore-shaped work-unit; not blocking other features.

### 4. Bash carve-out for D-051 (was priority 5; was session-3 priority 1)
**Files:** `bin/tbd.js`, `test/hook/`
**References:** D-051 deferred-Bash work; D-056 reduced pressure (navigator was main `.tbd/`-Bash caller, now bypassed cleanly). Demoted from #1 because session-4 discoveries (D-057, Q-038) and session-5 ratifications (D-058, D-059) are higher-leverage. Remaining motivation: pilot's read-only-with-redirect Bash (e.g. `cat foo >> .tbd/log.jsonl`) is still refused by `isReadOnlyBash`.
**Approach:** extract `>`/`>>` redirect targets from command text rather than regex-over-text. Still heuristic but precise. TDD-honest: failing tests for true positives (`echo X > .tbd/foo`) and true negatives (`echo ".tbd/ string" >> CHANGELOG.md`).

### 5. session-state.json counter maintenance (was priority 6)
**Files:** `bin/tbd.js`, possibly skills' SKILL.md content for orchestration
**Reference:** the navigator surfaced this drift across multiple session reviews (`vetoes_lifted` stayed at 0 while dissent log accumulated). Session-4 found it still at `s-2026-05-20-001` while sessions 2-4 had run; session-5 status TBD (likely still drifted). Likely subsumed by Q-037 resolution (session_id namespace decision).

### 6. current-intent.json cleanup convention (was priority 7)
**Reference:** the navigator surfaced repeatedly that current-intent.json drifted from the actual work as batches progressed. Conventions to decide: when to re-declare, when to close out (delete? archive? mark complete?), how intent transitions propagate to pa. Sessions 2-5 pattern: each work-unit re-declared (intent-003 test, intent-004 docs, intent-005 chore spike, intent-006 feat, intent-007 docs, intent-008 chore spike, intent-009 docs, intent-010 chore spike, intent-011 chore spike, intent-012 docs) and closed with `completion_summary` field. Worked cleanly but is convention-by-precedent rather than codified.

### 7. NEW: Intent-011 follow-on spike — resolve Q-039 + Q-040 (gated on fresh-session capability)
**Files:** `hooks/hooks.json` (TEMP matcher additions, revertable), `bin/tbd.js` (TEMP instrumentation, revertable), test fixtures.
**References:** Q-039 (CC loads hooks.json at session-start, mid-session edits don't reload), Q-040 (does CC fire PostToolUseFailure for Edit failures or only Write/Bash?). Both opened by intent-011 spike (session-5). Resolution unblocks safe action-trace coverage of failure events and decides whether a hot-reload mechanism exists.
**Approach (two sub-spikes, both gated on Q-039 own diagnosis — must start a FRESH session for the matcher additions to take effect):**
- Q-039 sub-spike: try documented mechanisms in order — `/hooks` slash command if available; plugin reload command if any; environment variable triggers; finally session-restart as the baseline. Observe whether each forces hooks.json to be re-read mid-session by adding a sentinel matcher block and triggering its event.
- Q-040 sub-spike: in a fresh session, register a `PostToolUseFailure:Edit` matcher block that appends to `/tmp/post-tooluse-failure.log`; trigger an Edit failure (no-match string). If the log gains an entry → CC fires PostToolUseFailure for Edit at the hook layer (OMC-reminder layer is just selectively-quiet for Edit). If zero entry → CC genuinely doesn't fire PostToolUseFailure for Edit, and action-trace must use a different mechanism for Edit-failure coverage (or accept the gap).
**Why priority 7 not earlier:** action-trace impl (priority 2) can ship without resolving Q-040 by accepting an Edit-failure-coverage gap with a clear TODO; that ship-now-fix-later trade-off keeps priority 2 unblocked. Q-039 + Q-040 are nice-to-have refinements, not load-bearing for the action-trace MVP.

### Closed in prior sessions
- ~~Add negative-case test for D-052 (success=false → no archive)~~ — DONE in `c78c3f2` (session 2)
- ~~Reconcile Q-035 — subagent tool calls and PreToolUse hooks~~ — DONE in `360d1e3` (session 3) — see D-056
- ~~Discover whether D-052 archive-pa actually works in production~~ — DONE in intent-008 spike (session 4, no commit; result documented as D-057 — it doesn't)
- ~~Resolve Q-038 — does CC PostToolUse fire on tool failure or only success?~~ — DONE in intent-011 spike (session 5, no commit; result documented as D-058 — fires only on success, n=4 corpus across Edit/Write/Bash + 2 distinct Bash failure modes; ratified in `b6a37b6`)
- ~~Resolve Q-036 — should hooks.json subscribe to PostToolUseFailure?~~ — DONE in intent-011 spike (session 5, no commit; result documented as D-059 — PostToolUseFailure is a distinct CC event, subscribing is feasible; gated on Q-039 fresh-session reload mechanism; ratified in `b6a37b6`)

---

## Open decisions to revisit during build

- **Q-002** (per-language non-interaction adapters) — needed when L2 reachability check lands
- **Q-019** (refactor behaviour-preservation check) — needed when refactor commit category is implemented
- **Q-030** (schema migration policy on `version:` bump) — needed at first version bump
- ~~**Q-036** (PostToolUseFailure subscription)~~ — **RESOLVED** session-5, see D-059 (event exists; subscribing feasible; Q-040 sub-question)
- **Q-037** (session_id namespace reconciliation) — needed at first action-trace populate (priority 2)
- ~~**Q-038** (does PostToolUse fire on failure?)~~ — **RESOLVED** session-5, see D-058 (fires only on success, n=4 corpus). Predicate-drop now part of priority 1.
- **Q-039** (mid-session hooks.json reload mechanism) — gates priority 7 follow-on spike; doesn't block priority 2 action-trace ship-now (PostToolUseFailure subscription can be added with a session-restart instruction)
- **Q-040** (Edit-failure PostToolUseFailure variant) — gates safe action-trace Edit-failure coverage; doesn't block priority 2 MVP (Edit-failure gap can ship with TODO)

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

---

## Session 4 progress (2026-05-20, intent-008 spike no-commit + intent-009 docs commit `<this commit>`)

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

---

## Session 5 progress (2026-05-20, intent-011 spike no-commit + intent-012 docs commits `b6a37b6` + `<this commit>`)

**Goal:** start with the obvious follow-on from session-4 — Q-038 multi-tool multi-failure-class spike (declared at session-start as priority 2). Resolve Q-038 so intent-010 can broaden its scope from fixture-only to fixture-plus-predicate-drop.

**Outcome:** Q-038 + Q-036 both resolved by intent-011's commit-less dual-probe spike (instrumentation in `bin/tbd.js#runArchivePa` capturing every PostToolUse payload to `/tmp/post-tooluse-failure.log` regardless of `success` state, plus a parallel PostToolUseFailure matcher block in `hooks/hooks.json`). n=4 failure-class corpus (Edit no-match + Write EROFS + Bash `false` + Bash `cat /nonexistent`) produced ZERO PostToolUse entries while in-window successes did fire → D-058 ratified. OMC-reminder layer surfaced `PostToolUseFailure:Write` (1×) + `PostToolUseFailure:Bash` (2×) → D-059 ratified. Edge case (no `PostToolUseFailure:Edit` reminder despite Edit-failure firing) flagged as Q-040 sub-question. Mid-session-hooks-reload-doesn't-work flagged as Q-039 (probe-2's PostToolUseFailure matcher was on-disk during the failure-trigger phase but never invoked — meaning the runtime never re-read hooks.json after session-start). Spike reverted cleanly in-session (`git diff bin/tbd.js hooks/hooks.json` empty post-revert per pa-069 + pa-070). Intent-012 ratified the four findings into DESIGN-LOG.md (`b6a37b6`) and this NEXT-SESSION.md (`<this commit>`) as two per-file commits.

### Three lessons worth carrying forward

- **Evidence proportional to claim weight is what the navigator was teaching all along.** Session-4 pa-057's D-058 attempt was downgraded to Q-038 on n=1 evidence — same content, same author, same logical claim — and session-5 pa-072's D-058 with n=4 corpus cleared on first review. The calibration isn't "behavioural observations always downgrade" or "navigator distrusts pilot synthesis," it's "the claim's strength must justify its weight on the design record." Pinning a decision that would justify removing defence-in-depth code is heavy; carrying it as an open question is light; the evidence needed to convert from one to the other is the strength of the corpus. **Pattern:** when next a pilot has a behavioural finding from one observation, ask "what would n=4 look like?" before drafting the pinned-decision text. Often the n=4 is cheap (intent-011's took ~5 tool calls and one revert) and produces a clean ratification path instead of a downgrade-then-recover cycle.

- **Per-file commits resolve a real diff_summary convention ambiguity.** Pilot.md says diff_summary derives from "git diff --stat (uncommitted) + the pending edit if not yet on disk" — strict reading = cumulative tree, lighter reading = per-pa-delta. pa-073 declared NEXT-SESSION.md only with DESIGN-LOG.md uncommitted in tree; navigator vetoed on skip-detection because the tree-state didn't match. Switching to per-file-per-commit (pa-074 commits DESIGN-LOG.md alone, then pa-075 declares NEXT-SESSION.md against clean tree) made the convention unambiguous: each pa describes its own pending change, and the tree is clean before each pa is reviewed. **Pattern:** when intent-scope spans multiple files, the cleanest workflow is commit-per-file rather than batch-edit-then-batch-commit. Slightly more ceremony per commit but eliminates the diff_summary ambiguity entirely. Bonus: matches TBD small-batches more strictly.

- **The Bash-pa-tool-match check fires before the navigator review.** This session's pa-071 → pa-072 reconciliation cycle (declaration coherence between intent and pa) was the first time the navigator's veto language explicitly flagged "the pa as written reads as if it's the complete work unit" vs intent's broader scope. The discipline didn't catch the over-broad pa-073 (declared NEXT-SESSION.md but tree had DESIGN-LOG.md changes) until I tried to invoke a state-changing action under it — at which point the navigator's review (not the hook's mechanical check) caught it. The hook's pa-tool-match invariant is necessary but not sufficient for declaration honesty; the navigator's diff-vs-declaration review is the layer that catches semantic mismatches. **Pattern:** treat the hook as the floor (skip-detection / pa-tool-match), and the navigator review as the ceiling (declaration coherence + small-batches scope + evidence-proportionality). Both must pass for a state-changing action to land; over-investing in either alone leaves a class of issue uncaught.

### Substrate observations for next session

- `dissent-log.jsonl` grew from ~32 entries to ~40+ entries this session (intent-011 spike cycles + intent-012 declaration-coherence veto on pa-071 + diff_summary veto on pa-073, both lifted on revision; pa-072 / pa-074 / pa-075 cleared first-pass). Two `veto_raised`/`veto_lifted` pairs in intent-012's docs work — both about coherence between substrate files (intent.description, pa.intent_str, pa.diff_summary, working tree), not about the underlying docs content.
- `current-intent.json` ended at intent-012 (this docs work-unit). Intent chain across session 5: 010 (no longer declared — folded into intent-013 plan), 011 (chore spike, no commit), 012 (docs, two commits `b6a37b6` + `<this commit>`).
- `bin/tbd.js` unchanged from session-3 baseline (`4b93fda`). Three carve-outs in `runVetoCheck` still in place; success predicate at `bin/tbd.js:199` still present (intent-013 will drop it per priority 1). Intent-011 spike's TEMP appendFileSync was added and reverted in-session — git diff baseline holds.
- `hooks/hooks.json` unchanged from session-3 baseline. Intent-011 spike's TEMP `PostToolUseFailure` matcher block was added and reverted in-session — but per Q-039 it was never actually invoked at runtime regardless, because CC loaded hooks.json at session-start and never re-read it.
- `/tmp/post-tooluse-failure.log` (intent-011 spike capture) is volatile and may be cleared between sessions; intent-013 / intent-014 spikes will likely re-capture via the same TEMP appendFileSync pattern.
- `.tbd/archive/` STILL doesn't exist on disk (intent-013 will fix this — the predicate-drop is what enables archive-pa to actually fire on real CC payloads). Verifiable post-intent-013 by `ls .tbd/archive/` returning a directory listing instead of ENOENT.
- Spike findings count across sessions: session-3 = 1, session-4 = 6, session-5 = 4 (D-058 + D-059 + Q-039 + Q-040). The dual-probe spike's marginal cost over single-probe was ~2 more tool calls; payoff was the Q-036 resolution coming "for free" alongside Q-038. Pattern: pre-declare the broader corpus before instrumentation, capture everything once, derive multiple decisions from one revert cycle.

# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-21 session-8 — first outside-in feature wave per session-7's strategic pivot. Intent-002 landed `/tbd:status` walking-skeleton in two commits (10a16cd flag registry; ab15365 SKILL.md + test + call-site, test GREEN 15/15). Intent-003 closed the session with NEXT-SESSION.md update and push. THREE VETO DISPUTES resolved in-session (regex tautology risk, sequencing/build-quality-in, small-batches working-tree contamination). DOGFOOD OUTPUT against real `.tbd/` surfaced six bites; TOP BITE = session-state counter maintenance, pinned for intent-004.
- **Trunk state:** main at `ab15365` (intent-002 step 2 — SKILL.md + test + call_sites bundled), pushed to origin (github.com/davewil/oh-my-tbd); reader can `git log -20` from HEAD for the full chain back to session-4's `515f2c9`
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## ▶ Next session pickup

**Session-8 confirmed the strategic pivot works.** Building `/tbd:status` walking-skeleton (the smallest outside-in feature) surfaced six concrete bites in one dogfood run against real `.tbd/` state — two were pre-predicted (counter drift, divergence-age), four were second-order surfaces from the stale `session_id` and from running the skill mid-session. Each becomes its own narrow intent. The next session picks the top bite and drops down.

### Session-9 priority 1: intent-004 = session-state counter maintenance (TOP BITE)

Type: **fix** OR **feature** (depending on framing — see below). One declarable purpose, narrow file scope.

**Why this bite first:** Highest leverage. The `<drifted>` sentinel for `vetoes_raised=0 / vetoes_lifted=0` was the strongest signal in the session-8 dogfood — the counters are demonstrably wrong (dissent-log has ~10+ veto events in this session alone, archive has 63 pa-cycles), and the SKILL.md state-machine assumes honest counters. Fix once, every future `/tbd:status` invocation gets cleaner output.

- **Source of truth:** `.tbd/dissent-log.jsonl` (veto_raised / veto_lifted / veto_held / human_resolved events) and `.tbd/archive/<session>/` (archived pa-cycles).
- **Where to wire:** `bin/tbd.js` PostToolUse handler — increment the relevant `session-state.json.counts.*` field when the corresponding event fires. Per D-058, only success-path PostToolUse fires reliably (this is fine — we want counts of *completed* events anyway).
- **Type decision:** `fix` if framed as "counters lie"; `feature` if framed as "counter machinery is new code path". Lean `fix` — the field exists, it just isn't maintained.
- **TDD sequencing:** failing test for counter increment on a synthetic dissent-event → minimal handler → re-run inside this session and verify counter moves.
- **Stretch goal (defer if it grows):** session_id rollover — `session-state.json.session_id` is still `s-2026-05-20-001` two days after starting. Q-037 (session_id namespace) is relevant. Likely separates into intent-005.

### Six dogfood bites surfaced by session-8 (priority order — first becomes intent-004)

| # | Bite | Intent-N candidate | Notes |
|---|---|---|---|
| 1 | **session-state counter drift** (counts vs dissent-log + archive) | intent-004 (this session's priority 1) | TOP BITE — see above |
| 2 | **divergence-age helper missing** (all three axes `<unknown>`) | intent-005 likely | branch-age + uncommitted-WIP-age + stash-age per D-050 |
| 3 | **session_id stale across day boundary** | intent-005 or merged with #1 | Q-037-relevant |
| 4 | **current-intent.json `status` field convention** | intent-006 or docs | implicit-open via absent `completed_at` is brittle |
| 5 | **archived_pas "since session start" anchor breaks when session_id is stale** | gated on #3 | resolves with session_id rollover |
| 6 | **dissent_events "since session start" anchor ambiguous** | gated on #3 | same root as #5 |

### Suggestion state-machine (reference — full version is canonical in `skills/status/SKILL.md`)

| Detected state | Next suggestion |
|---|---|
| `.tbd/` directory does not exist | `/oh-my-tbd:init` (when implemented) — bootstrap project |
| `.tbd/veto.json` exists with `status: standing` | Address the standing veto: revise the pa, or file dissent |
| `.tbd/pending-action.json` exists & no standing veto | Invoke the navigator subagent for review |
| No current-intent (or `status: completed`) & working tree dirty | `/oh-my-tbd:start <type> "<description>"` |
| No current-intent & working tree clean & local ahead of origin | `git push origin main` |
| Current-intent open & working tree clean & no pending-action | Declare next pa, or close intent |
| Current-intent open & working tree dirty & no pending-action | Declare pa for the changes |
| Everything clean, intent closed, nothing ahead | `/oh-my-tbd:start` next work-unit (or stop) |
| Unknown state | "Unknown state — manual investigation needed" + raw state dump |

Future skills (`/oh-my-tbd:init`, `/oh-my-tbd:flag`, `/oh-my-tbd:audit`, `/oh-my-tbd:retro`, `/oh-my-tbd:doctor`, etc.) plug into new rows as they land.

### Deferred — preserved as historical context, NOT the active queue

The active queue is the six bites above. These are kept here because past sessions surfaced them and they may yet matter; pursue only if real feature use surfaces a concrete need.

- **Principle propagation** (was intent-018 priority-0) — codify small-batches=size+reviewability-not-singularity in `principles/principles.md` and the navigator rubric. Currently lives only in `0785a38`'s commit body.
- **`working_tree_state` pa-disclosure idiom** (NEW, session-8) — surfaced via pa-021's veto-lift. Useful for any mid-flight accumulating-bundle situation. Worth canonicalising in `principles-additions.md` or SCHEMAS.md.
- **action-trace.jsonl population** — `bin/tbd.js` PostToolUse handler with handler-ordering + carve-out coverage. Will be needed for retro/audit features. Adjacent to intent-004 counter work; may co-land.
- **TS migration** (D-038) — chore-shaped; revisit when feature surface is larger.
- **Bash carve-out for D-051** — read-only-Bash refused. Surfaced twice in session-8 as friction on test-run + grep verification. Now empirically demonstrated, no longer hypothetical — still not blocking.
- **Intent-011 follow-on spike** Q-039 + Q-040 — gated on fresh-session capability; not blocking anything currently.
- **Q-041 substrate anomaly** (opened intent-018) — pa-archived-without-Edit-firing. Did NOT reproduce in session-8 (15 pa-cycles, all clean). Either narrowed surface (only navigator-dissent-log-write path?) or the pattern is intermittent. Re-investigate when action-trace handler-ordering work touches the same code site.

---

## Where we are

**Walking-skeleton + D-052/D-056/D-057/D-058/D-059/D-060 all landed; substrate-state model is honest end-to-end on CC's event-firing semantics AND the implementation matches those assumptions; action-trace.jsonl population is the unblocked next work-unit (now priority 1 after intent-010/intent-013 closure).** Commit sequence (after `030cb17 Bootstrap`):

| Commit | What |
|---|---|
| `dd03552` | **(session 6)** intent-013 — `fix: restore D-052 archive-pa for real CC payloads + close D-056 symmetry gap`. Five atomic changes bundled: (1) `test-d052-archive-on-success.sh` fixture swapped from synthetic to captured-real CC Edit PostToolUse payload (per D-057); (2) `bin/tbd.js` dropped `tool_response.success !== true` predicate + its orphan local binding (per D-058); (3) NEW `test-q036-navigator-bypass-in-archive-pa.sh` RED→GREEN regression test; (4) `bin/tbd.js` added navigator-agent-type carve-out at top of `runArchivePa` (D-060 candidate, ratified in `e21af40`); (5) `test-d052-archive-on-failure.sh` DELETED (asserted unreachable failure-path per D-058; test-of-unreachable-code is dishonesty per session-4 fixture-honesty lesson). 17 pa-cycles across implementation. All 5 hook tests PASS post-fix. `.tbd/archive/` finally exists on disk. |
| `ca24bcc` | **(session 6)** intent-014 — `docs: log Mode A / Mode B operating-mode calibration in NEXT-SESSION`. Single-file +21/-0 docs commit logging the project-level operating-mode framework (Mode A bootstrap = rigour over throughput, current; Mode B deliverable = human-developer pace, future) and the four transition criteria. Surfaces feature-landing pace concern explicitly for resume across sessions. 3 pa-cycles, 0 vetoes. |
| `e21af40` | **(session 6)** intent-015 commit A — `docs: pin D-060 — archive-pa navigator-agent-type carve-out (D-056 symmetry partner)`. Single +1/-0 row in DESIGN-LOG.md's Pinned-decisions table ratifying the D-060 candidate forecast in dd03552's commit body. D-060 is the design-record landing of dd03552 change 4 (navigator agent_type bypass in runArchivePa); empirical basis pa-082/083/086 visible in `.tbd/archive/s-2026-05-20-001/`. Fails closed: degraded-but-not-broken if `agent_type` missing. |
| `854f8c7` | **(session 6)** intent-015 commit B — NEXT-SESSION.md restructure: header pointers updated to session-6, commit table extended with the four session-6 rows, "Where we are" Net-result paragraph updated (intent-010/intent-013 done → priority queue collapses 7→6; `.tbd/archive/` now exists on disk), priority queue restructured (action-trace.jsonl population promoted to priority 1), session-6 progress block appended per session-5 template. Per-file-per-commit split per session-5 pa-073 first-remedy precedent. |
| `9e765e2` | **(session 6)** intent-016 — `docs: archive per-session progress into sessions/ + trim NEXT-SESSION.md`. Extracts the inlined Session-1..Session-6 progress/lessons blocks (~165 lines) into dedicated `sessions/session-N.md` files (verbatim move + uniform header schema), moves historical commit-table rows for sessions 1-5 into each session-N.md's commit-chain section, and adds a new compact 'Past sessions' index to NEXT-SESSION.md. Goal: NEXT-SESSION.md becomes a lean resume doc (~150 lines down from ~315). Also adds `sessions/README.md` as a layout description. Five-veto pa-109..pa-115 trail captures a real Mode-A failure mode (declaration-vs-reality drift on full-file Writes); see session-6 follow-on lessons. |
| `8efe4a2` | **(session 7)** intent-017 — `docs: resolve three deferred `<this commit>` placeholders → 9e765e2`. Three surgical Edits on NEXT-SESSION.md L5/L6/L21 directly applying intent-016's commit-body lesson on declaration-vs-reality drift across pa-109..pa-117 — lesson held: three Edits each cleared first review. ONE FORMAL VETO DISPUTE (first in project history): pa-121 vetoed on declaration-vs-reality drift; navigator misread mid-work-unit `git diff` as the pending Edit's effect rather than pa-120's already-applied effect; pilot dissented in dissent-log.jsonl 22:38Z; navigator re-reviewed against working-tree grep and lifted, logging retro note: `git diff at Edit-stage shows cumulative effect of cleared-and-fired Edits; pending Edits exist only in pa.intent_str until cleared; verification must use grep on working-tree files`. ONE SUBSTRATE ANOMALY: pa-121 archived prematurely during the dispute cycle before its Edit fired — opens Q-041 for intent-019 action-trace design (suspected D-056 carve-out hole or PostToolUse-on-navigator-Edit consuming pilot pa). 6 pa-cycles total (pa-119 declaration → pa-120/pa-122/pa-123 Edits → pa-124 commit → pa-125 push). UX OBSERVATION: pa-NNN identifiers are process-language in Mode A; durable tag-field schema change deferred to Mode B feature work where content-tags would be meaningful. |
| `0785a38` | **(session 7)** intent-018 — `docs: session-7 close-out — NEXT-SESSION.md + Q-041`. NEXT-SESSION.md restructured with the strategic pivot framing (recursion-break) plus Q-041 row in DESIGN-LOG.md. |
| `c094246` | **(session 7→8 bridge)** intent-001 — `docs: NEXT-SESSION.md next-session pickup marker`. Added prominent '▶ Next session pickup' marker with /tbd:status walking-skeleton scope, 9-row state-machine, expected-bites list. SECOND Q-041 reproduction observed (pa-006 archived prematurely during navigator review writing dissent-log.jsonl) — narrows the substrate anomaly to "navigator-side writes to .tbd/dissent-log.jsonl during reviews appear to consume the pilot's pending-action." |
| `10a16cd` | **(session 8)** intent-002 step 1 — `feat: register tbd_status_skill flag`. Inaugurates `.tbd/flags.yaml` as the registry file (first flag in the repo), Layer-1 `flag_system: none` convention encoded (presence of `skills/<name>/SKILL.md` is the gate). Single +14/-0 file. 3 pa-cycles. |
| `ab15365` | **(session 8)** intent-002 step 2 — `feat: /tbd:status walking-skeleton — SKILL.md + test + flag call_site`. Three files bundled per flag-call-site-registered watch-forward: `skills/status/SKILL.md` (new, 98L; encodes 9-row state-machine + `<unknown>`/`<drifted>` sentinel rule + Next: line), `test/skill/test-status-walking-skeleton.sh` (new, 128L; structural assertions on SKILL.md, GREEN 15/15 PASS exit 0; also echoes 9 human-graded fixture descriptions for dogfood scaffolding), `.tbd/flags.yaml` (+4/-1 call_sites populated). FIVE constituent pa-cycles (pa-012 test create → pa-013 SKILL.md → pa-014 call_sites → pa-017 test row-1 pattern fix → pa-021 test row-4 pattern fix). THREE VETOES dispute-resolved in-session: (1) regex tautology risk on 'relax patterns' narration — lifted with literal before/after + discriminating-test claim; (2) sequencing — test re-run mandatory before next Edit per build-quality-in; (3) small-batches working-tree contamination — lifted with new `working_tree_state` pa-field idiom (navigator suggested canonicalising in a future docs intent). |
| `<this commit>` | **(session 8)** intent-003 — `docs: session-8 close-out — NEXT-SESSION.md + skill-namespace alignment`. NEXT-SESSION.md restructure (header pointers session-7→session-8, ▶ Next session pickup rewritten to point at intent-004 = counter maintenance, commit table extended with five new rows, Net-result/Decisions/Open-questions paragraphs updated to session-8 outcomes, Past sessions index extended). Bundled `/tbd:` → `/oh-my-tbd:` namespace correction in the state-machine and Future-skills table rows — consistency-with-reality (the actual skills at `skills/start/SKILL.md` L7, `skills/override/SKILL.md` L7, `skills/status/SKILL.md` L7 all use `/oh-my-tbd:`; the old NEXT-SESSION.md tables had docs-drift). FOUR VETOES this work-unit (one held + sustained-then-lifted on the cumulative-diff misread pa-028→pa-029, third occurrence of the pa-121 pattern); navigator pinned this for amplify-learning candidate in principles-additions. |

**Net result:** Session-8 confirms the outside-in pivot works. `/tbd:status` walking-skeleton landed in two commits with the smallest viable scope, the dogfood against real `.tbd/` state surfaced **six concrete bites** (two pre-predicted, four second-order from stale session_id) — each becomes its own narrow intent. The TOP BITE = session-state counter maintenance is pinned for intent-004 (next session). The `working_tree_state` pa-field idiom (surfaced via pa-021 dispute lift) is a durable contribution beyond intent-002's declared scope, worth canonicalising in `principles-additions.md`. Mode A discipline held end-to-end: 15 pa-cycles inside intent-002, four veto disputes inside intent-003, every veto either lifted with revision or sustained-with-corrective-action. NEW EMPIRICAL DATUM on Q-041: did NOT reproduce in session-8's 15+4 pa-cycles — pattern narrowed (no longer "every dissent-log write"; possibly intermittent or specific to longer pa-chains).

**Decisions added this session:** None pinned to DESIGN-LOG.md. Session-8 produced the `working_tree_state` pa-disclosure convention as informal precedent; ratification deferred to its own future docs intent.

**Open questions opened this session:** None new. Q-039, Q-040, Q-041 remain open from prior sessions.

---

## Operating-mode calibration (project-level, logged 2026-05-20 end of session 6)

Two operating modes acknowledged after the user observed feature-landing pace is too slow for adoption-viability. **Currently in Mode A.** Sessions 1–6 cadence (≈1 commit per session, heavy navigator ceremony, much time on substrate-of-substrate) is accepted FOR THIS PHASE; it would NOT be accepted once the plugin is the deliverable.

### Mode A — bootstrap (current)
Rigour over throughput. The dogfood loop catches real bugs (D-057, D-058, D-059, intent-013's D-056-symmetry-gap) and the navigator vetoes catch real overclaims (intent-013 pa-091: orphan `toolResponse` binding flagged as "completion of change 2, not separate cleanup"). Session-level cadence (1 commit per session, 5–17 pa-cycles per commit) is accepted. **Finite scope:** make the discipline machinery itself trustworthy. Don't optimise for feature pace.

### Mode B — deliverable (future)
The plugin must land features at human-developer pace or no one adopts it. Realistic batch ceilings, lighter ceremony on routine work, automatic counters + trace so substrate maintenance isn't manual, complete carve-out matrix so a normal feature commit doesn't take 17 pa-cycles. **Mode-B viability is the gate on broader distribution.**

### Transition criterion (Mode A → Mode B)
Worth pinning when one of us spots the moment. All four required:
1. `archive-pa` + `action-trace.jsonl` + `session-state.json` counters all working end-to-end (so substrate is honest without pilot maintenance). `archive-pa` shipped intent-013 today; action-trace + counters remain priority work.
2. Divergence-cap + batch-cap actually read by code (so the discipline enforces its named primitives, not just its ceremony).
3. Navigator per-pa friction sub-30-seconds on routine work (so ceremony doesn't dominate). Today's average is ≈90s per navigator review.
4. Successful "outside" test: take a small unrelated repo, plug in oh-my-tbd, deliver one real feature, measure friction. This is the dispositive evidence Mode B is real and not just self-reported.

**Until met, sessions look like today. After, they shouldn't.** If a future session catches itself producing one substantive commit per 3+ hours of work AFTER the four criteria above are met, surface immediately — that's a regression from Mode B.

---

## What to do next (priority order — updated post-session-6)

### 1. action-trace.jsonl population (was priority 2 — promoted)
**Files:** `bin/tbd.js` (PostToolUse path)
**Reference:** D-018, COMPONENTS.md, plus session-4 design-fork resolutions from advisor synthesis.
**Approach:** when veto-check returns allow AND PostToolUse fires (i.e. tool succeeded per D-058), append a single line to `.tbd/action-trace.jsonl` capturing tool, per-tool args (`file_path` for Edit/Write, `command_redacted` via existing `redact()` for Bash), `pending_action_ref` (read from pa file before archive-pa consumes it — see handler-ordering question in original advisor synthesis), `session_id`, `tool_use_id`, `agent_type`, timestamp, decision. Coverage includes carve-out paths (D-051 substrate writes, D-056/D-060 navigator actions) with `pending_action_ref: null` flagging them — gating on "pa existed" loses visibility into exactly the carve-out cases the discipline lets through. Q-025 (rotation) deferred: add TODO comment near append site, real growth data after a few sessions decides threshold. PostToolUseFailure subscription (per D-059) deferrable — Edit-failure coverage gap can ship with TODO per Q-040.

### 2. TS migration kickoff (per D-038, was priority 3)
**Files:** `src/` (currently empty placeholder), `package.json` (currently absent), `bin/` (compiled output)
**References:** D-038 pinned; user surfaced in session 4 that typed `HookInput`/`ToolResponse` against real CC payload shapes (captured for success cases in `/tmp/post-tooluse-payload.log`, and now corroborated for failure-event shapes via intent-011 spike) would have prevented D-057 at compile time. Walking-skeleton JS was bootstrap simplicity; substrate semantics are now honest enough to be worth typing.
**Approach:** stand up `tsc` build chain, output to `bin/`. Define `HookInput` / `ToolResponse` / `PendingAction` / `Veto` / `SessionState` types from captured real payloads (not from SCHEMAS.md idealised examples). Port `bin/tbd.js` line-by-line preserving behaviour — every hook test must still pass. Per D-053, a chore-shaped work-unit; not blocking other features.

### 3. Bash carve-out for D-051 (was priority 4)
**Files:** `bin/tbd.js`, `test/hook/`
**References:** D-051 deferred-Bash work; D-056/D-060 reduced pressure (navigator was main `.tbd/`-Bash caller, now bypassed cleanly across both runVetoCheck and runArchivePa). Remaining motivation: pilot's read-only-with-redirect Bash (e.g. `cat foo >> .tbd/log.jsonl`) is still refused by `isReadOnlyBash`.
**Approach:** extract `>`/`>>` redirect targets from command text rather than regex-over-text. Still heuristic but precise. TDD-honest: failing tests for true positives (`echo X > .tbd/foo`) and true negatives (`echo ".tbd/ string" >> CHANGELOG.md`).

### 4. session-state.json counter maintenance (was priority 5)
**Files:** `bin/tbd.js`, possibly skills' SKILL.md content for orchestration
**Reference:** the navigator surfaced this drift across multiple session reviews (`vetoes_lifted` stayed at 0 while dissent log accumulated). Session-4 found it still at `s-2026-05-20-001` while sessions 2-4 had run; session-6 status TBD (likely still drifted). Likely subsumed by Q-037 resolution (session_id namespace decision).

### 5. current-intent.json cleanup convention (was priority 6)
**Reference:** the navigator surfaced repeatedly that current-intent.json drifted from the actual work as batches progressed. Conventions to decide: when to re-declare, when to close out (delete? archive? mark complete?), how intent transitions propagate to pa. Sessions 2-6 pattern: each work-unit re-declared (intent-003 test, intent-004 docs, intent-005 chore spike, intent-006 feat, intent-007 docs, intent-008 chore spike, intent-009 docs, intent-010 chore spike, intent-011 chore spike, intent-012 docs, intent-013 fix, intent-014 docs, intent-015 docs) and closed with `completion_summary` field. Worked cleanly but is convention-by-precedent rather than codified.

### 6. Intent-011 follow-on spike — resolve Q-039 + Q-040 (was priority 7; gated on fresh-session capability)
**Files:** `hooks/hooks.json` (TEMP matcher additions, revertable), `bin/tbd.js` (TEMP instrumentation, revertable), test fixtures.
**References:** Q-039 (CC loads hooks.json at session-start, mid-session edits don't reload), Q-040 (does CC fire PostToolUseFailure for Edit failures or only Write/Bash?). Both opened by intent-011 spike (session-5). Resolution unblocks safe action-trace coverage of failure events and decides whether a hot-reload mechanism exists.
**Approach (two sub-spikes, both gated on Q-039 own diagnosis — must start a FRESH session for the matcher additions to take effect):**
- Q-039 sub-spike: try documented mechanisms in order — `/hooks` slash command if available; plugin reload command if any; environment variable triggers; finally session-restart as the baseline. Observe whether each forces hooks.json to be re-read mid-session by adding a sentinel matcher block and triggering its event.
- Q-040 sub-spike: in a fresh session, register a `PostToolUseFailure:Edit` matcher block that appends to `/tmp/post-tooluse-failure.log`; trigger an Edit failure (no-match string). If the log gains an entry → CC fires PostToolUseFailure for Edit at the hook layer (OMC-reminder layer is just selectively-quiet for Edit). If zero entry → CC genuinely doesn't fire PostToolUseFailure for Edit, and action-trace must use a different mechanism for Edit-failure coverage (or accept the gap).
**Why priority 6 not earlier:** action-trace impl (priority 1) can ship without resolving Q-040 by accepting an Edit-failure-coverage gap with a clear TODO; that ship-now-fix-later trade-off keeps priority 1 unblocked. Q-039 + Q-040 are nice-to-have refinements, not load-bearing for the action-trace MVP.

### Closed in prior sessions
- ~~Add negative-case test for D-052 (success=false → no archive)~~ — DONE in `c78c3f2` (session 2)
- ~~Reconcile Q-035 — subagent tool calls and PreToolUse hooks~~ — DONE in `360d1e3` (session 3) — see D-056
- ~~Discover whether D-052 archive-pa actually works in production~~ — DONE in intent-008 spike (session 4, no commit; result documented as D-057 — it doesn't)
- ~~Resolve Q-038 — does CC PostToolUse fire on tool failure or only success?~~ — DONE in intent-011 spike (session 5, no commit; result documented as D-058 — fires only on success, n=4 corpus across Edit/Write/Bash + 2 distinct Bash failure modes; ratified in `b6a37b6`)
- ~~Resolve Q-036 — should hooks.json subscribe to PostToolUseFailure?~~ — DONE in intent-011 spike (session 5, no commit; result documented as D-059 — PostToolUseFailure is a distinct CC event, subscribing is feasible; gated on Q-039 fresh-session reload mechanism; ratified in `b6a37b6`)
- ~~Replace synthetic D-052 test fixture AND drop the `bin/tbd.js:199` success predicate in one commit (intent-010, BROADENED)~~ — DONE in intent-013 (`dd03552`, session 6) as a five-atomic-change bundle: fixture swap, predicate drop, NEW navigator-bypass regression test, navigator-bypass carve-out in `runArchivePa` (D-060 candidate), and DELETION of `test-d052-archive-on-failure.sh` (unreachable-path test = dishonesty per session-4 fixture-honesty lesson). D-060 ratified in `e21af40`. `.tbd/archive/` now exists on disk.

---

## Open decisions to revisit during build

- **Q-002** (per-language non-interaction adapters) — needed when L2 reachability check lands
- **Q-019** (refactor behaviour-preservation check) — needed when refactor commit category is implemented
- **Q-030** (schema migration policy on `version:` bump) — needed at first version bump
- ~~**Q-036** (PostToolUseFailure subscription)~~ — **RESOLVED** session-5, see D-059 (event exists; subscribing feasible; Q-040 sub-question)
- **Q-037** (session_id namespace reconciliation) — needed at first action-trace populate (priority 1)
- ~~**Q-038** (does PostToolUse fire on failure?)~~ — **RESOLVED** session-5, see D-058 (fires only on success, n=4 corpus). Predicate drop landed in intent-013.
- **Q-039** (mid-session hooks.json reload mechanism) — gates priority 6 follow-on spike; doesn't block priority 1 action-trace ship-now (PostToolUseFailure subscription can be added with a session-restart instruction)
- **Q-040** (Edit-failure PostToolUseFailure variant) — gates safe action-trace Edit-failure coverage; doesn't block priority 1 MVP (Edit-failure gap can ship with TODO)

---

## Past sessions

For depth on what previous sessions decided or learned, follow these links. Each `sessions/session-N.md` contains the verbatim progress block + commit chain from that session.

- **[Session 6](sessions/session-6.md)** (2026-05-20, commits `dd03552 → 854f8c7`) — intent-013/014/015: substrate-honesty bug-trio closed (D-057 fixture mismatch + D-058 PostToolUse-fires-only-on-success + D-056 symmetry gap), D-060 ratified, Mode A/B operating-mode framework logged. `.tbd/archive/` exists on disk for the first time.
- **[Session 5](sessions/session-5.md)** (2026-05-20, commits `b6a37b6 → 5ee090a`) — intent-011 dual-probe spike resolves Q-038/Q-036 → D-058/D-059. n=4 failure-class corpus across Edit/Write/Bash. Per-file-per-commit hygiene crystallizes. Q-039/Q-040 opened.
- **[Session 4](sessions/session-4.md)** (2026-05-20, commit `515f2c9`) — intent-008 spike reveals archive-pa silent-broken in production (no `success` field in real CC payloads). D-057 ratified; Q-036/Q-037/Q-038 opened. Evidence-proportionality lesson via pa-057 sustained-then-lifted veto.
- **[Session 3](sessions/session-3.md)** (2026-05-20, commits `360d1e3 → 4b93fda`) — Q-035 / D-056 navigator-agent-type carve-out in `runVetoCheck`. 5-minute spike pattern crystallizes. First navigator-written dissent-log entry.
- **[Session 2](sessions/session-2.md)** (2026-05-20, commits `c78c3f2 → 95bff0e`) — D-052 archive-on-failure negative-case test (since DELETED in intent-013 on fixture-honesty grounds). Mutation-table-by-inspection lesson.
- **[Session 1](sessions/session-1.md)** (2026-05-20, commits `e082866 → 5443f48`, 10 commits) — Walking-skeleton + D-051/D-052/D-053. First dogfood. Self-archive lockout discovered and fixed. The discipline becomes self-bootstrapping AND self-correcting.

See also `sessions/README.md` for the layout convention.

## Files to read on resume (~5-10 minutes)

1. `README.md` — orient
2. This file (`NEXT-SESSION.md`)
3. `DESIGN-LOG.md` § Pinned decisions — recent entries are D-046 → D-060
4. `DESIGN-LOG.md` § Open questions — recent entries Q-028 → Q-040
5. `.tbd/dissent-log.jsonl` — the empirical record from sessions 1–6 (note: per-session progress blocks now live in `sessions/session-N.md`; the dissent log remains the cross-session pa-cycle audit trail)
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
ls .tbd/archive/                  # post-intent-013 this is non-empty
claude --plugin-dir .             # load the plugin in dev mode — pilot becomes default main agent
```

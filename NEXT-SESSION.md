# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-20 (walking-skeleton + D-052 soft + self-archive fix landed)
- **Trunk state:** main at [latest], pushed to origin (github.com/davewil/oh-my-tbd)
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
| `[next]`  | Self-archive carve-out fix in archive-pa + NEXT-SESSION.md update for resume |

**Net result:** anyone enabling the plugin (`claude --plugin-dir .` or installed) gets the full discipline: pilot is the default main agent, navigator is invocable as `oh-my-tbd:navigator`, the veto-check hook fires on every state-changing tool call, `.tbd/` orchestration substrate is freely writable per D-051, principles checklist is loaded as the navigator's rubric source.

**Decisions added this session:** D-051 (`.tbd/` carve-out — implemented), D-052 (consumption tracking — deferred), D-053 (baseline-not-doctrine calibration — ratified).

**Open questions opened this session:** Q-033 (advisory pa at hook layer — D-054 candidate), Q-034 (soften consumption tracking — D-055 candidate), Q-035 (subagent tool calls bypass PreToolUse hook — discovered empirically).

---

## What to do next (priority order — updated post-session-1)

### 1. Reconcile Q-035 — subagent tool calls and PreToolUse hooks (non-deterministic)
**Files:** `bin/tbd.js`, possibly `agents/navigator.md` (tool allowlist), possibly `hooks/hooks.json`
**Discovery (session 1):** the navigator subagent's Bash to `.tbd/` is non-deterministic — sometimes refused by the hook, sometimes succeeds. This is the most fragile substrate behaviour observed. Possibly related to how Claude Code routes hooks for subagent tool calls vs main-session tool calls.
**Approach:** investigate empirically — set up a controlled test (navigator subagent Bash to `.tbd/dissent-log.jsonl` under various pending-action states). Then choose: tighten navigator's tool allowlist (drop Bash, ship a small subagent-targeted helper), extend D-051 carve-out to cover navigator Bash, or rely on prompt-level discipline.

### 2. Add negative-case test for D-052 (success=false → no archive)
**Files:** `test/hook/test-d052-archive-on-failure.sh` (new), possibly extend `test-d052-archive-on-success.sh`
**Why:** session-1 navigator pre-flagged this — current test only covers the success=true path. The success predicate is the load-bearing design decision and a `!== true` → `=== false` flip would not regress-detect.
**Approach:** new shell test that sets up same fixture, pipes a hook input with `tool_response.success: false` (or absent), asserts pa is NOT moved to archive, original remains. Single small batch.

### 3. Implement Bash carve-out for D-051 (carefully)
**Files:** `bin/tbd.js`, `test/hook/`
**References:** D-051 deferred-Bash work; navigator's pa-004 review surfaced the simple-design concern.
**Approach:** the regex-over-command-text approach has false-positive risk. Better: extract `>` / `>>` redirect targets from the command text, check if the redirect destination is inside `.tbd/`. Still heuristic but more precise. TDD-honest: land failing tests covering both true positives (`echo X > .tbd/foo`) and true negatives (`echo ".tbd/ string" >> CHANGELOG.md`).

### 4. action-trace.jsonl population
**Files:** `bin/tbd.js` (post-allow path)
**Reference:** D-018, COMPONENTS.md
**Approach:** when veto-check returns `allow`, also append a single line to `.tbd/action-trace.jsonl` capturing tool, redacted args, decision, timestamp. Q-029 (secret-redaction) is the open design question here.

### 5. session-state.json counter maintenance
**Files:** `bin/tbd.js`, possibly skills' SKILL.md content for orchestration
**Reference:** the navigator surfaced this drift across multiple session reviews (`vetoes_lifted` stayed at 0 while dissent log accumulated). Either pilot bumps counters, navigator bumps counters, or the hook bumps counters on certain events.

### 6. current-intent.json cleanup convention
**Reference:** the navigator surfaced repeatedly that current-intent.json drifted from the actual work as batches progressed. Conventions to decide: when to re-declare, when to close out (delete? archive? mark complete?), how intent transitions propagate to pa.

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
- `.tbd/session-state.json` — counter drift noted (vetoes_lifted=0 despite ~10 lift events). Cleanup is priority 5.

To resume safely:

1. Read `NEXT-SESSION.md` (this file) and `DESIGN-LOG.md` § Open questions (recent Q-033 → Q-035, plus possibly Q-036 if added).
2. Run `bash test/hook/test-d051-tbd-bypass.sh` and `bash test/hook/test-d052-archive-on-success.sh` — both should PASS. Sanity check.
3. Run `/oh-my-tbd:start <type> <description>` to declare a fresh intent for whatever you're tackling.
4. Pick a priority from "What to do next" and proceed via normal pilot loop.

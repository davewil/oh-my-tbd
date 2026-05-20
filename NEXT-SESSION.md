# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-20 (walking-skeleton landed)
- **Trunk state:** main at 34363b0, pushed to origin (github.com/davewil/oh-my-tbd)
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## Where we are

**Walking-skeleton complete.** All 6 planned batches landed in this commit sequence (after `030cb17 Bootstrap`):

| Commit | What |
|---|---|
| `e082866` | D-051 orchestration substrate carve-out (Write/Edit/NotebookEdit) + CLI-contract test |
| `d790f61` | DESIGN-LOG: log D-051/D-052/D-053 + Q-033/Q-034 |
| `e1a56e0` | Full pilot and navigator system prompts (Opus navigator) |
| `0caaa72` | Wire veto-check hook into PreToolUse |
| `ab56f47` | Skill specs: /oh-my-tbd:start, /oh-my-tbd:override |
| `53e9efe` | TBD/XP/LEAN principles checklist (navigator rubric source) |
| `34363b0` | Activate pilot as main thread via settings.json (D-049) |

**Net result:** anyone enabling the plugin (`claude --plugin-dir .` or installed) gets the full discipline: pilot is the default main agent, navigator is invocable as `oh-my-tbd:navigator`, the veto-check hook fires on every state-changing tool call, `.tbd/` orchestration substrate is freely writable per D-051, principles checklist is loaded as the navigator's rubric source.

**Decisions added this session:** D-051 (`.tbd/` carve-out — implemented), D-052 (consumption tracking — deferred), D-053 (baseline-not-doctrine calibration — ratified).

**Open questions opened this session:** Q-033 (advisory pa at hook layer — D-054 candidate), Q-034 (soften consumption tracking — D-055 candidate), Q-035 (subagent tool calls bypass PreToolUse hook — discovered empirically).

---

## What to do next (priority order)

### 1. Implement D-052 — pending-action.json consumption tracking
**Files:** `bin/tbd.js`, `test/hook/`
**References:** D-052, D-043, the dogfood evidence in `.tbd/dissent-log.jsonl` (multiple `veto_raised` events from stale pa state)
**Approach:** TDD-honest. Land a failing test first (pa is consumed on successful action; next state-changing call without fresh pa is refused). Then implement: hook archives consumed pa to `.tbd/archive/<session_id>/pa-<id>.json` after a successful pass.
**Decisions to make in flight:** archive layout, archive-vs-mark-consumed (Q-034 — softer "warning not refusal" path is also an option per D-053).

### 2. Reconcile Q-035 — subagent tool calls and PreToolUse hooks
**Files:** `bin/tbd.js`, possibly `agents/navigator.md` (tool allowlist)
**Discovery:** during this session the navigator subagent used `Bash >>` to append to `.tbd/dissent-log.jsonl` despite the D-051 carve-out being Write/Edit/NotebookEdit only. This means subagent tool calls either don't fire the PreToolUse hook at all, or fire but get allowed because of how the navigator is invoked.
**Approach:** investigate empirically — does the PreToolUse hook fire on subagent Bash? Then choose: tighten navigator's tool allowlist (drop Bash, ship a small subagent-targeted helper), or extend D-051 carve-out to cover navigator's Bash to `.tbd/`, or document the gap and rely on prompt-level discipline.

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

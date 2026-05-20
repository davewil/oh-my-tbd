# Session 1 — 2026-05-20 — Walking-skeleton bootstrap + first dogfood

**Intents:** intent-001, intent-002, and pre-intent walking-skeleton work
**Commits:** `e082866` → `5443f48` (10 commits)
**Outcome headline:** TBD plugin walking-skeleton lands; first dogfood surfaces D-051 (orchestration substrate carve-out), D-052 (pa single-shot consumption tracking), D-053 (discipline calibration); self-archive lockout discovered and fixed; the discipline becomes self-bootstrapping AND self-correcting.

---

## Commit chain

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

## Lessons worth carrying forward

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

1. Read `NEXT-SESSION.md` (this file) and `DESIGN-LOG.md` § Open questions (recent Q-033 → Q-040).
2. Run `bash test/hook/test-d051-tbd-bypass.sh` and `bash test/hook/test-d052-archive-on-success.sh` and `bash test/hook/test-d052-self-archive-skip.sh` and `bash test/hook/test-q035-navigator-agent-bypass.sh` and `bash test/hook/test-q036-navigator-bypass-in-archive-pa.sh` — all five should PASS. Sanity check. (Note: `test-d052-archive-on-failure.sh` was DELETED in intent-013 — see session-6 lessons for rationale.)
3. Run `/oh-my-tbd:start <type> <description>` to declare a fresh intent for whatever you're tackling.
4. Pick a priority from "What to do next" and proceed via normal pilot loop.

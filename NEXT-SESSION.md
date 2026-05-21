# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-21 session-9 — **architectural reset**. Mid-session diagnosis: the project had drifted from XP into a cargo-cult gatekeeper architecture (heavy pa-coordination, jsonl audit chain, courthouse vocabulary). Ran a five-value pass (communication → simplicity → feedback → courage → respect) that produced concrete structural decisions, then shipped the first two thinning slices under the still-existing discipline.
- **Trunk state:** main at `cc63d72` (slice 2 — README override references removed), pushed to origin. Slice 1 (`804065a` — counter-recompute machinery removed) is the immediately prior commit.
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## ▶ Session-10 priority 1: rewrite `agents/pilot.md`

`agents/pilot.md` (~280 lines) is the system prompt every pilot session loads. It currently encodes the gatekeeper architecture in detail — and it's the bottleneck blocking every remaining slice, because the prompts that reference deprecated surfaces have to stop referencing them before those surfaces can be deleted.

### What the rewrite must change

**Out:**
- The pa-cycle ceremony ("Before every state-changing tool call, write `.tbd/pending-action.json`...")
- "Veto / standing veto / escalated veto / blocked action / refuse" vocabulary
- The dissent-log protocol ("append entry to `.tbd/dissent-log.jsonl`...")
- `/oh-my-tbd:override` references
- The "Step 1 declare intent → Step 4 invoke navigator → Step 5 read veto" loop
- Skip-detection language (D-043) — the hook that does the skip-detection is being collapsed in slice 6
- Courthouse vocabulary throughout ("hard refuse", "the discipline is mechanical and the discipline is yours", "you do not bypass")

**Stays:**
- XP practices proper: small commits, test-first on features and fixes, frequent integration to trunk, divergence-age awareness, behaviour-preservation on `refactor`-type work, refactors as first-class commits not bundled with features
- "Discipline / rigour / the pair upholds" vocabulary (not "enforce / compliance")
- The intent-declaration practice (still useful as a tiny note) — but as a one-line note, not a falsifiable contract
- Brief forward-reference to the sidecar pair (b2 default, b3 human-on-request) — even though the sidecar itself isn't built yet
- Brief reference to the s3 narrow safety hook: will refuse only `git push --force`, `git reset --hard`, `git branch -D` against trunk (lands in slice 6)

**New shape, in one paragraph:**
> You're the pilot. Do XP: small commits, test-first on features and fixes, push frequently. Declare what you're working on in a one-line note (`.tbd/current-intent` — tiny, conversational). When the sidecar speaks up in chat (it shares your context; it will object on the four things the pair watches for — missing test, oversized batch, divergence-age, mixed concerns), engage with what it says. The hook only refuses chainsaw operations on trunk; everything else is conversation.

---

## Session-9 architectural reset decisions

All ratified conversationally in session-9 (see transcript). Don't relitigate.

- **(b2)** Sidecar pair is the default — same context as the pilot, advisory text in main thread. NOT a separate Agent subagent: Claude Code's `Agent` tool gives subagents fresh context by design, so "shared context" via that tool is impossible. The honest shape is "same agent in a different posture, or a hook-emitted prompt." Sidecar is **deferred** to a later session — ship the thinning first, learn from pilot-only behaviour, then decide the sidecar shape.
- **(b3)** Human-as-pair on request — toggled via `/tbd:pair-with-me` or project default.
- **(s3)** Narrow safety hook — refuse only `git push --force`, `git reset --hard`, `git branch -D` against trunk. No pa-coordination. Everything else is conversation.
- **(f1)** Cut counters / metrics nobody acts on. Done in slice 1.
- **(r2)** Annotated supersedence — `DESIGN-LOG.md` entries stay; mark superseded with forward pointer to the new shape. Don't erase history.
- **(c2)** Incremental deletion in small batches, each shipped to trunk. Do NOT build the new shape alongside the old — delete the old, ship, then grow into the cleared space.
- **Three-category split:** discipline (conversational, the pair's voice), safety (mechanical, fat-finger guard against irrecoverable history rewrites), audit (conversation + git log + reflog only — no jsonl files).
- **Per-turn cadence** for the sidecar (when built) — with explicit license to stay silent.

---

## Slices shipped this session

1. **`804065a`** — `fix: remove counter-recompute machinery (intent-006 slice 1)`. Removed `recomputeCounts` function and its `try/finally` caller from `bin/tbd.js`; deleted companion test `test/hook/test-counter-recompute-on-posttooluse.sh`. Reason: `vetoes_lifted=114 > vetoes_raised=27` was structurally impossible; counters were decoration nobody acted on. Net -273 lines.
2. **`cc63d72`** — `docs: remove README references to /oh-my-tbd:override (intent-006 slice 2)`. Two README edits removing the override bullet (L16) and the override mention in the skills list (L38). Narrowed from a broader scope after `small-batches` veto v-053 caught the bundle attempt (skill+audit+README was three sub-slices in one pa).

Both pushed to origin/main. All 6 remaining tests still GREEN.

---

## Remaining slices (necessary order)

3. **Rewrite `agents/pilot.md`** (priority 1 next session). See above. Unblocks 4–5. Big, careful work — the system prompt encodes a lot of legacy machinery. Type=`docs` is the simplest fit even though it changes operational behaviour (the new prompt won't tell the pilot to write pa.json before each tool call); rationale is the same "rubric doesn't cleanly fit architectural-reset slices" framing intent-006 used.
4. **Rewrite `agents/navigator.md`** — possibly delete entirely. Decision deferred to when slice 3 is done and we see what role (if any) the navigator agent plays during the rest of the thinning.
5. **Delete `skills/override/SKILL.md`** + `.tbd/pilot-responses.jsonl` + clean up references in `SCHEMAS.md`, `COMPONENTS.md`. Bundled because of the dangling-reference cascade v-053 caught. Gated on slices 3+4.
6. **Collapse `veto-check` hook to s3** — `bin/tbd.js` + `hooks/hooks.json` + rewrite 5 of 6 hook tests (which currently test the heavy pa-coordination). After this lands, future slices don't pay pa-cycle ceremony.
7. **Delete runtime files** — `pending-action.json`, `veto.json`, `session-state.json`, `dissent-log.jsonl`, `navigator-questions.jsonl`. `.gitignore` cleanup. Gated on slice 6.
8. **(r2) annotated supersedence pass** — `DESIGN-LOG.md`, `COMPONENTS.md`, `SCHEMAS.md` updates marking the superseded sections with forward pointers. New compact section in DESIGN-LOG.md reflecting the post-reset shape.

---

## Dogfood meta-finding (worth carrying forward)

Every veto raised on slices 1 + 2 was substantively valid:
- v-052 — intent-type mismatch (`refactor` claimed but behaviour changed; needed `fix`)
- v-052 (rec) — test deletion missing from same commit
- v-053 — commit message body not declared inline; diff_summary numbers wrong by 2×
- v-052 (rec on pa-060) — pa narrative-vs-diff confusion (pre-action workflow)
- v-053 on pa-062 — bundled three sub-slices into one Bash; gitignored-file false claim; dangling-reference cascade

The discipline-as-implemented is upholding rigour. It also cost ~10 minutes of round-trips per slice (~6 vetoes resolved by revision, no overrides used). The first observation is why slice 6 (hook collapse) is the structurally important move — the same kinds of catches need to happen in the new shape, but as conversational voice from a sidecar that shares the pilot's context, not as a hook that refuses keystrokes via JSON state files.

---

## Reading order for resume (5–10 minutes)

1. This file
2. `README.md` — current user-facing surface (slim, recently cleaned)
3. `agents/pilot.md` — the system prompt you'll load by default, **then mentally apply the corrections in "What the rewrite must change" before doing work**
4. `git log -5 --stat cc63d72` — see slices 1 and 2 as landed
5. The session-9 opening prompt (provided by the human at session-start, mirrors the directives above)

## Quick-resume commands

```bash
cd /Volumes/Personal/Users/davidwilliams/dev/trunk/
git log --oneline -5
git status
ls .tbd/
bash test/hook/test-d051-tbd-bypass.sh   # smoke-test — should PASS
```

---

## Past sessions

Per (r2): history preserved; supersession explicit.

- **Session 9** (2026-05-21, this session — to be archived to `sessions/session-9.md` in slice 8) — **architectural reset**. Values-pass produced (b2)+(b3)+per-turn+tiny-note+(s3)+(f1)+(r2)+(c2). Slices 1+2 shipped: `804065a` (counter machinery removed) and `cc63d72` (README override refs).
- **[Session 8](sessions/session-8.md)** (2026-05-21, commits `10a16cd → ab15365`) — `/oh-my-tbd:status` walking-skeleton landed. Intent-005 (discuss-skill) started but step 2 deferred; **now superseded by session-9 reset**.
- **[Session 7](sessions/session-7.md)** (2026-05-20) — strategic pivot away from recursive process-mapping toward real-project dogfood. Q-041 substrate anomaly opened (Q-039/Q-040 still open).
- **[Session 6](sessions/session-6.md)** (2026-05-20, commits `dd03552 → 854f8c7`) — substrate-honesty bug-trio closed (D-057/D-058/D-060); Mode A/B operating-mode framework logged.
- **[Session 5](sessions/session-5.md)** (2026-05-20, commits `b6a37b6 → 5ee090a`) — intent-011 dual-probe spike resolves Q-038/Q-036 → D-058/D-059.
- **[Session 4](sessions/session-4.md)** (2026-05-20, commit `515f2c9`) — intent-008 spike reveals archive-pa silent-broken in production. D-057 ratified.
- **[Session 3](sessions/session-3.md)** (2026-05-20, commits `360d1e3 → 4b93fda`) — Q-035 / D-056 navigator-agent-type carve-out.
- **[Session 2](sessions/session-2.md)** (2026-05-20, commits `c78c3f2 → 95bff0e`) — D-052 archive-on-failure negative-case test (since DELETED).
- **[Session 1](sessions/session-1.md)** (2026-05-20, commits `e082866 → 5443f48`, 10 commits) — Walking-skeleton + D-051/D-052/D-053.

See also `sessions/README.md` for the per-session-file convention.

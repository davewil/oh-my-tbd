# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-22 session-10 — **architectural-reset thinning complete**. 8 slices shipped (3 → 10), ~1,800 lines removed across code, prompts, schemas, runtime files, and obsolete docs/skills. The repo is now structurally at the post-reset shape the session-9 values-pass described.
- **Trunk state:** main at `d47bf9f`, pushed to origin.
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## ▶ Session-11 priority 1: build back up — write the post-reset docs

The thinning is done. What's on disk now matches the session-9 vision (thin XP-prompt + narrow-safety-hook + stub for the deferred sidecar). The four design docs — `COMPONENTS.md`, `SCHEMAS.md`, `VALIDATION.md`, `DESIGN-LOG.md` — were written for the *pre-reset* architecture and don't match the code anymore. They each carry a one-paragraph "rewrite pending" notice from slice 10 pointing here.

Session-11's priority-1 work is the **honest post-reset rewrite** of those docs. The user's frame from session-10 was *"pair back and then build back up with the change of direction"* — that's exactly the framing for this work. Don't try to salvage the old docs; rewrite each as a fresh description of what's actually shipped, with deletion of pre-reset content treated as a first-class outcome rather than a loss.

### What each doc should describe (post-reset)

**`COMPONENTS.md`** — currently ~360 lines describing navigator subagent, pa-coordination flow, the 4-layer skip-detection model, /tbd:swap / /tbd:navigator-review / /tbd:declare-intent skills (planned but never built), a shared-blackboard architecture. Post-reset: maybe 50 lines.

- `agents/pilot.md` — the system prompt (XP under TBD discipline, intent as sticky note, the pair stub forward-reference, the s3 safety hook)
- `skills/pair/SKILL.md` — the stub for the deferred sidecar
- `bin/tbd.js` — the safety-check subcommand + version
- `hooks/hooks.json` — one PreToolUse Bash matcher
- `test/hook/test-s3-narrow-refuse-on-trunk.sh` — the 11-case regression test
- `principles/principles.md` — XP/TBD/LEAN reference reading (no longer rubric-as-code, but still useful for the pilot to read)
- `settings.json` — activates `pilot` as the default agent
- `.tbd/flags.yaml` — flag registry (just `tbd_pair_skill` after the cleanup)
- `.tbd/current-intent.json` — session-local sticky note, gitignored

**`SCHEMAS.md`** — currently ~440 lines describing 9+ schema files. Post-reset: maybe 30 lines.

- `current-intent.json` — informal, conversational. No JSON Schema. Maybe document a suggested shape (`{type, description}`) but emphasise it's a note, not a contract.
- `flags.yaml` — the flag registry. Document the entry shape and the layer-1 walking-skeleton convention (presence of SKILL.md is the gate).
- That's it. No pending-action, no veto, no dissent-log, no session-state, no navigator-questions, no pilot-responses.

**`VALIDATION.md`** — currently anchored on navigator detection rate, false-positive rate of vetoes, sessions-with-zero-vetoes metric. Post-reset: maybe 40 lines.

- One hook test stays GREEN (11 cases pin the s3 refuses)
- Pilot behaviour judged by dogfood feedback: does it actually practise XP under the prompt?
- A healthy session has a couple of mild objections from the pair (currently the human), quick revisions, quiet flow. Zero objections might mean the pair is asleep; constant friction means the work unit is too big or the discipline is miscalibrated. (This phrasing is already in pilot.md's "Validating the discipline" section — VALIDATION.md should be the structured companion.)
- Honest "what we don't measure": there's no longer a corpus-detection-rate or veto-rate-stability metric, because there's no rubric-as-code to drift against. The discipline is now the pilot's behaviour-under-prompt + the human's reaction to it; measurement is fundamentally human-judged.

**`DESIGN-LOG.md`** — per session-9 decision (r2): **annotated supersedence**. History preserved; superseded entries marked with forward pointers. Most of D-008 through D-053 (~30 entries) describe deprecated machinery. Each affected entry needs a one-line note:

> *Superseded by session-9 architectural reset (commit 6aecdad onward). The [navigator subagent / pa-coordination / dissent log / skip-detection / ...] was removed in favour of [the thin XP-prompt + s3 safety hook]. See COMPONENTS.md (post-rewrite) for the current shape.*

Then add a fresh section at the top describing the post-reset architecture's pinned decisions:

- The five-value frame (communication / simplicity / feedback / courage / respect) ratified in session-9
- The 8 structural decisions from session-9 ((b2) sidecar default deferred, (b3) human-as-pair on request, per-turn cadence, tiny-note intent, (s3) narrow safety hook, (f1) drop counters/metrics, (r2) annotated supersedence, (c2) incremental deletion)
- The three-category split (discipline = conversational; safety = mechanical; audit = git log + reflog + conversation)
- The dogfood meta-finding: every veto in slices 1-2 was substantively valid AND cost ~10 minutes round-trip → why the gatekeeper shape was a category error

### Slice plan for session-11

A reasonable order (small-batches, each shipped to trunk):

1. **`COMPONENTS.md` rewrite** — fresh top-to-bottom. Delete the old, write the new.
2. **`SCHEMAS.md` rewrite** — same.
3. **`VALIDATION.md` rewrite** — same.
4. **`DESIGN-LOG.md` annotated supersedence** — add post-reset section at top; mark superseded entries with forward pointers; leave history intact. Big slice; may want to split if it gets unwieldy.
5. **Cross-doc-link sweep** — make sure README/NEXT-SESSION/agents/pilot.md all point at the rewritten docs consistently. Likely small.

After slice 5, the docs match the code. Decide what's next (see "Forward-looking" below).

---

## What shipped this session

8 slices, all on `origin/main`:

| # | Commit | Type | Slice | Net |
|---|---|---|---|---|
| 3 | `6aecdad` | docs | Rewrite `agents/pilot.md` (XP-centred, 151→102 lines) | -49 |
| 4 | `df7f4a8` | docs | Add "Validating the discipline" section to pilot.md | +4 |
| 5 | `271c6ef` | feat | Stub `/oh-my-tbd:pair` skill (+ flag entry + pilot.md reference rename) | +37 |
| 6 | `c3bf21b` | fix | **Collapse veto-check hook to s3 narrow safety check** | -449 |
| 7 | `db6c3d8` | chore | Delete `agents/navigator.md` | -206 |
| 8 | `35975d1` | chore | Delete `skills/start`, `skills/status`, `skills/override` + sweep dead flag entries | -311 |
| 9 | `8998444` | chore | Delete runtime files in `.tbd/` + slim `.gitignore` | -11 |
| 10 | `d47bf9f` | docs | README post-reset cleanup + stale-notice headers on COMPONENTS/SCHEMAS/VALIDATION | +2 |

**Total: ~-983 lines from this session, ~-1,800 across the whole architectural reset (sessions 9+10).**

Slice 6 was the pivotal one: the hook collapse retired the ceremony tax (pa.json writes, navigator subagent round-trips, PostToolUse archive consumption). Slices 7–10 then ran ~5× faster than slices 3–5 because of it.

### Post-reset repo inventory

What's actually on disk after slice 10 (the user surface):

```
oh-my-tbd/
├── agents/
│   └── pilot.md                     # XP-centred system prompt
├── skills/
│   └── pair/SKILL.md                # stub — forward-references deferred sidecar
├── bin/
│   └── tbd.js                       # ~220 lines: safety-check subcommand + version
├── hooks/
│   └── hooks.json                   # one PreToolUse Bash matcher
├── test/hook/
│   └── test-s3-narrow-refuse-on-trunk.sh   # 11 cases, GREEN
├── principles/
│   └── principles.md                # XP/TBD/LEAN reference reading
├── settings.json                    # activates pilot as default agent
├── .tbd/
│   ├── flags.yaml                   # just tbd_pair_skill
│   └── current-intent.json          # one-line sticky note, gitignored
├── README.md                        # post-reset (slice 10)
├── DESIGN-LOG.md                    # pre-reset content + slice-10 notice header
├── COMPONENTS.md                    # pre-reset content + slice-10 notice header
├── SCHEMAS.md                       # pre-reset content + slice-10 notice header
├── VALIDATION.md                    # pre-reset content + slice-10 notice header
└── NEXT-SESSION.md                  # this file
```

The plugin is now: **a system prompt + a fat-finger guard hook + a stub**. Out-of-box user experience is `claude --plugin-dir .` → pilot agent active by default + safety hook live → start working in XP mode. Nothing else mediates the session.

---

## What gets built back up (the change of direction)

The session-9 architectural reset paid back design complexity that wasn't earning its keep. The session-10 thinning made that real on disk. What comes next is the *build-back-up* phase — but now the additions can be judged against the post-reset baseline: *does this earn its keep against the conversation + git-log audit model?*

### Forward-looking (open decisions, don't relitigate yet — surface in session-11 after docs)

**(1) The sidecar mechanism — what's it look like?**
Session-9 deferred `(b2)`. The pilot.md forward-reference describes *what* the sidecar does (objects on missing test / oversized batch / divergence-age / mixed concerns in chat) but not *how* it's wired. Two candidate shapes worth designing:

- **Hook-emitted prompt** — a PostToolUse (or similar) hook that emits an injected `<system-reminder>` voicing the four objections when triggered. Synchronous, shared context (Claude Code's own context, not via Agent tool). Cheapest to implement. Risk: noisy if naive; needs careful trigger conditions.
- **Same-context persona switch** — the pilot itself adopts a momentary "pair voice" turn when triggered (via a slash command, a hook-emitted prompt, or pilot-initiated self-reflection). No second agent; the model speaks twice in one turn. Risk: model may not actually shift posture; needs sharp prompting.

Both are options (ii) from the session-9 framing. Which earns its keep depends on what objections actually catch real things — measurable only by running the post-reset plugin for a few real sessions first.

**(2) Is there work that lives in skills, post-reset?**
After slices 8–10 the only skill is `/oh-my-tbd:pair` (the stub). The deleted skills (`start`, `status`, `override`) all existed to mediate gatekeeper machinery that's gone. Are there skills that earn their keep against the conversation model? Candidates worth considering only after a few sessions of dogfood:

- A retrospective skill that scans `git log` for the session and surfaces patterns (commits ratio, message quality, divergence age)
- A "show me the discipline state" skill replacing the old `status` — but for what? `git status` already shows everything that matters now
- A "split this commit" / "rebase this work" coaching skill — possibly useful, definitely YAGNI right now

Don't pre-decide. Let the conversational discipline run for a few sessions first; build skills only when something actually feels worth turning into a one-liner.

**(3) The plugin's value proposition.**
The honest post-reset value: a system prompt that coaches XP behaviour + a hook that prevents irrecoverable git mistakes + a forward-pointer to a yet-to-be-built sidecar. *Is this worth being a plugin* vs. a `CLAUDE.md` recipe + a git pre-push hook?

- The safety hook is the strongest plugin-vs-recipe argument — `CLAUDE.md` can't refuse tool calls, plugin hooks can.
- The pilot agent appearing in `/agents` (vs. living in CLAUDE.md) is a discoverability win — multi-project users invoke it explicitly.
- The plugin shape gives a clean path for the sidecar to grow without users having to update CLAUDE.md.

Probably yes, plugin earns its keep — but worth being honest in the post-reset README and DESIGN-LOG that the value is *narrower* than the original design implied.

---

## Reading order for resume (5–10 minutes)

1. This file
2. `README.md` — current user-facing surface (post-reset, recently cleaned)
3. `agents/pilot.md` — the system prompt session-11 loads by default
4. `git log --oneline -10` — see the 8-slice thinning
5. `COMPONENTS.md`, `SCHEMAS.md`, `VALIDATION.md`, `DESIGN-LOG.md` — post-reset rewrites (session-11 slices 1–4). Start with COMPONENTS for the inventory, then SCHEMAS for the (small) data contract, then the post-reset section at the top of DESIGN-LOG for the structural decisions that produced this shape.

## Quick-resume commands

```bash
cd /Volumes/Personal/Users/davidwilliams/dev/trunk/
git log --oneline -10
git status
bash test/hook/test-s3-narrow-refuse-on-trunk.sh   # should PASS (11 cases)
node bin/tbd.js version                            # should print "oh-my-tbd 0.1.0 (post-reset)"
```

---

## Past sessions

Per (r2): history preserved; supersession explicit.

- **Session 10** (2026-05-22, this session) — **architectural-reset thinning complete**. 8 slices: pilot.md rewrite + Validating-the-discipline section + pair stub + **hook collapse to s3 (the pivotal slice)** + delete navigator + delete dead skills + delete runtime files + README cleanup with stale-notice headers on the three docs deferred to session-11.
- **Session 9** (2026-05-21) — **architectural reset**. Values-pass produced (b2)+(b3)+per-turn+tiny-note+(s3)+(f1)+(r2)+(c2). Slices 1+2 shipped: `804065a` (counter machinery removed) and `cc63d72` (README override refs).
- **[Session 8](sessions/session-8.md)** (2026-05-21) — `/oh-my-tbd:status` walking-skeleton landed. Intent-005 (discuss-skill) started but step 2 deferred; **now superseded by session-9 reset**.
- **[Session 7](sessions/session-7.md)** (2026-05-20) — strategic pivot away from recursive process-mapping toward real-project dogfood. Q-041 substrate anomaly opened.
- **[Session 6](sessions/session-6.md)** (2026-05-20) — substrate-honesty bug-trio closed (D-057/D-058/D-060); Mode A/B operating-mode framework logged.
- **[Session 5](sessions/session-5.md)** (2026-05-20) — intent-011 dual-probe spike resolves Q-038/Q-036 → D-058/D-059.
- **[Session 4](sessions/session-4.md)** (2026-05-20) — intent-008 spike reveals archive-pa silent-broken in production. D-057 ratified.
- **[Session 3](sessions/session-3.md)** (2026-05-20) — Q-035 / D-056 navigator-agent-type carve-out.
- **[Session 2](sessions/session-2.md)** (2026-05-20) — D-052 archive-on-failure negative-case test (since DELETED).
- **[Session 1](sessions/session-1.md)** (2026-05-20) — Walking-skeleton + D-051/D-052/D-053.

See also `sessions/README.md` for the per-session-file convention.

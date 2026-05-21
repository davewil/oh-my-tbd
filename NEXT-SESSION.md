# Next-Session Continuation

Working notes for resuming after a session restart. Read this first.

- **Last session ended:** 2026-05-22 session-11 — **post-reset docs rewrite complete**. 9 slices shipped (1 → 9). The four design docs *plus* `principles/principles.md` now match what's on disk; the architectural reset is fully reflected in both code and prose.
- **Trunk state:** main at `e09eb42` (slice 8 — principles.md rewrite). Slice 9 patches this hand-off doc.
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## ▶ Session-12 priority 1: live with the post-reset shape

Session-11 closes the deletion/rewrite era. The plugin's surface is now:

- `agents/pilot.md` — the system prompt (XP under TBD discipline)
- `skills/pair/SKILL.md` — the deferred-sidecar stub
- `bin/tbd.js` — the CLI (safety-check subcommand + version)
- `hooks/hooks.json` — one PreToolUse matcher
- `test/hook/test-s3-narrow-refuse-on-trunk.sh` — 11-case regression test, GREEN
- `principles/principles.md` — XP/TBD/LEAN reference reading
- `settings.json` — `{"agent": "pilot"}`
- `.tbd/flags.yaml` + `.tbd/current-intent.json` — small data plane
- Four design docs that actually describe this — see [COMPONENTS.md](./COMPONENTS.md), [SCHEMAS.md](./SCHEMAS.md), [VALIDATION.md](./VALIDATION.md), [DESIGN-LOG.md](./DESIGN-LOG.md).

**Session-12 priority-1 is the simplest possible thing: run a real session under this shape and see what happens.** Pick any genuine piece of work — a feature, a bug, a refactor — and execute it with the pilot prompt active and the human acting as the pair. Don't pre-pick a session topic for instrumentation; pick a real one because it earns its keep, and treat the session itself as evidence about the post-reset shape.

The three forward-looking decisions deferred from session-11 (sidecar mechanism, skill inventory, value-prop framing) only earn data once the plugin has been lived in for a few real sessions. Don't open them speculatively.

### Signals worth watching during the first lived-in session

- **Where does the pair voice (the human, for now) actually fire?** Which of the four objections (missing test / oversized batch / divergence-age / mixed concerns) come up most? Which never come up? That's data about which a future sidecar should prioritise.
- **What does the human want a one-liner for that doesn't currently exist?** That's a candidate skill. Don't build it yet — note it.
- **Where does the s3 safety hook nearly fire and you're glad it didn't, or where do you almost want it to fire?** That's calibration data for whether the narrow refusal set is correctly drawn.
- **Where does the pilot prompt visibly produce different behaviour vs. running without the plugin?** That's the value-prop story.

Notes go in the conversation; commit messages carry the narrative; `git log` is the retrospective surface.

---

## What shipped this session

9 slices, all on `origin/main`:

| # | Commit | Type | Slice | Net |
|---|---|---|---|---|
| 1 | `cec7a8f` | docs | Rewrite `COMPONENTS.md` against post-reset shape (354 → 43 lines) | -328 |
| 2 | `c7b1987` | docs | Rewrite `SCHEMAS.md` against post-reset shape (451 → 64 lines) | -386 |
| 3 | `22fc361` | docs | Rewrite `VALIDATION.md` against post-reset shape (99 → 56 lines) | -42 |
| 4 | `63f574d` | docs | `DESIGN-LOG.md` annotated supersedence per (r2) — fresh top section + ~28 superseded IDs | +94 |
| 5 | `9fa8314` | docs | Cross-doc-link sweep: pilot.md filename alignment + README status polish + NEXT-SESSION reading-order fix | 0 |
| 6 | `1c7a86e` | chore | Delete orphan `test/skill/test-status-walking-skeleton.sh` | -128 |
| 7 | `3cc7c80` | docs | NEXT-SESSION.md close-out (initial, since patched in slice 9) | -57 |
| 8 | `e09eb42` | docs | Rewrite `principles/principles.md` as reference reading (280 → 178 lines) | -102 |
| 9 | _(this commit)_ | docs | Patch NEXT-SESSION.md close-out to reflect slice 8 | ~ |

**Total: ~-950 lines from this session.** Combined with sessions 9+10 (~-1,800 from the reset), the project is roughly **-2,750 lines** lighter than its pre-reset peak, while now describing what's actually shipped.

### Session-11 character

Quiet flow throughout. Two advisor objections that earned their keep:

1. At session start the advisor caught the `.tbd/current-intent` (no extension) vs. `.tbd/current-intent.json` (actual on-disk name) drift between pilot.md and disk — slice 5 resolved it.
2. After the apparent close-out (slice 7), the advisor ran a residual-drift check and caught `principles/principles.md` still describing pre-reset rubric machinery (navigator-walks-this, veto.json, action-trace.jsonl, skip-detection, adversarial corpus, L0/L1/L2/L3) despite COMPONENTS.md claiming the file is "reference reading" — slice 8 rewrote it as actual reference reading, and slice 9 patched this hand-off doc to match.

No mixed-concerns issues, no oversized batches, no divergence creeping. Each slice was a single declarable thing, shipped to trunk within a few minutes. The safety-hook regression test stayed GREEN throughout.

The two advisor catches are the most interesting datum from the session: when a session believes it is "done", a residual-drift check against the docs' own claims still found something to fix. That's a reliable signal worth keeping for session-12 onward — apparent done isn't done until the doc-claims-against-disk-content check passes.

---

## Forward-looking (open decisions, defer to session-12+)

Three decisions worth opening, but only once a few real sessions have produced data:

**(1) The sidecar mechanism — what's it look like?**
Session-9 deferred `(b2)`. `agents/pilot.md` §"The pair" describes *what* the sidecar does (objects on missing test / oversized batch / divergence-age / mixed concerns in chat) but not *how* it's wired. Two candidate shapes worth designing:

- **Hook-emitted prompt** — a PostToolUse (or similar) hook that emits an injected `<system-reminder>` voicing the four objections when triggered. Synchronous, shared context (Claude Code's own context, not via Agent tool). Cheapest to implement. Risk: noisy if naive; needs careful trigger conditions.
- **Same-context persona switch** — the pilot itself adopts a momentary "pair voice" turn when triggered (via a slash command, a hook-emitted prompt, or pilot-initiated self-reflection). No second agent; the model speaks twice in one turn. Risk: model may not actually shift posture; needs sharp prompting.

Both are option (ii) from the session-9 framing. Which earns its keep depends on what objections actually catch real things — measurable only by running the post-reset plugin for a few real sessions first.

**(2) Is there work that lives in skills, post-reset?**
After slices 6–10 last session and slice 6 this session, the only skill is `/oh-my-tbd:pair` (the stub). The deleted skills (`start`, `status`, `override`) all existed to mediate gatekeeper machinery that's gone. Are there skills that earn their keep against the conversation model? Candidates worth considering only after a few sessions of dogfood:

- A retrospective skill that scans `git log` for the session and surfaces patterns (commits ratio, message quality, divergence age)
- A "show me the discipline state" skill replacing the old `status` — but for what? `git status` already shows everything that matters now
- A "split this commit" / "rebase this work" coaching skill — possibly useful, definitely YAGNI right now

Don't pre-decide. Let the conversational discipline run for a few sessions first; build skills only when something actually feels worth turning into a one-liner.

**(3) The plugin's value proposition — honest framing.**
Partially addressed in slice 5: `README.md` no longer claims "bootstrap (commit #1) — no discipline yet." The honest post-reset value: a system prompt that coaches XP behaviour + a hook that prevents irrecoverable git mistakes + a forward-pointer to a yet-to-be-built sidecar.

The remaining question: *is this worth being a plugin* vs. a `CLAUDE.md` recipe + a git pre-push hook?

- The safety hook is the strongest plugin-vs-recipe argument — `CLAUDE.md` can't refuse tool calls, plugin hooks can.
- The pilot agent appearing in `/agents` (vs. living in CLAUDE.md) is a discoverability win — multi-project users invoke it explicitly.
- The plugin shape gives a clean path for the sidecar to grow without users having to update CLAUDE.md.

Probably yes, plugin earns its keep — worth confirming in DESIGN-LOG as a fresh entry once a few sessions of lived experience exist.

---

## Reading order for resume (5–10 minutes)

1. This file
2. `README.md` — current user-facing surface (post-reset)
3. `agents/pilot.md` — the system prompt session-12 loads by default
4. `git log --oneline -10` — see the 9-slice docs-rewrite session
5. `COMPONENTS.md`, `SCHEMAS.md`, `VALIDATION.md`, `DESIGN-LOG.md` — the docs now match the code; the post-reset section at the top of `DESIGN-LOG.md` ratifies the session-9 framing

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

- **Session 11** (2026-05-22, this session) — **post-reset docs rewrite complete**. 9 slices: COMPONENTS / SCHEMAS / VALIDATION full rewrites, DESIGN-LOG annotated supersedence (session-9 (r2)), cross-doc-link sweep, orphan-test deletion, close-out, principles.md rewrite (advisor-caught residual drift), and this hand-off patch. Docs now match code.
- **Session 10** (2026-05-22) — **architectural-reset thinning complete**. 8 slices: pilot.md rewrite + Validating-the-discipline section + pair stub + **hook collapse to s3 (the pivotal slice)** + delete navigator + delete dead skills + delete runtime files + README cleanup with stale-notice headers on the three docs deferred to session-11.
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

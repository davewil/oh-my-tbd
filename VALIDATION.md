# oh-my-tbd — Validation Plan (v0)

> ⚠️ **This document describes the pre-reset architecture.** Session-9 (2026-05-21) ratified a deep architectural reset that removed the navigator subagent and the corpus-detection-rate / veto-rate-stability metrics anchored on it. The post-reset validation surface is much smaller: one hook test (`test/hook/test-s3-narrow-refuse-on-trunk.sh`, 11 cases) and human-judged dogfood feedback on whether the pilot prompt produces XP behaviour. A post-reset rewrite is pending — see [NEXT-SESSION.md](./NEXT-SESSION.md) for the current shape.

What "v0 done" looks like. Numbers are placeholders pending first telemetry; calibrated empirically during dogfooding.

- **Status:** skeleton (pre-reset; rewrite pending)
- **Started:** 2026-05-19
- **Companion to:** `DESIGN-LOG.md`, `COMPONENTS.md`, `SCHEMAS.md`

---

## 1. Navigator quality bar

The navigator's value depends on it actually catching things. Without measurement, "engineered difference" is hopeful design (per D-025).

| Metric | Target (placeholder) | How measured |
|---|---|---|
| Adversarial-corpus detection rate | ≥ 90% | Plugin CI runs known-bad diff corpus through navigator; counts correctly-raised vetoes |
| Principle diversity in detection | ≥ 80% of principle categories represented across corpus runs | Veto distribution across `principle` field values |
| False-positive rate (paired-mode) | ≤ 20% of vetoes overridden by human | `overrides.jsonl` / `dissent-log.jsonl` ratio |
| Veto-rate stability across prompt revisions | Δ ≤ 10% absolute on same corpus | Regression check before any navigator prompt change ships |

**Failure modes to watch for:**
- Veto rate near 0% across many sessions → navigator is rubber-stamping; investigate
- Veto rate near 100% → navigator is over-strict; investigate
- One principle dominates vetoes → other principles aren't being checked; investigate

## 2. Veto-rate health band

Per-session counts from `dissent-log.jsonl`:

| Metric | Target band | Reasoning |
|---|---|---|
| Vetoes per session | TBD after first 20 dogfood sessions | Empirical baseline |
| Sessions with zero vetoes | < 10% | Either pilot is perfect or navigator is asleep — both worth investigating |
| Median dissent-log entries per session | TBD | Health signal for engagement |

## 3. Override-rate ceiling

| Metric | Target | Source |
|---|---|---|
| Human override rate | ≤ 15% of raised vetoes | `overrides.jsonl` |
| Recurring override-reason categories | Surfaced in `/tbd:retro` | Triggers rule revision when a reason recurs ≥ 3 times |
| Autonomous-mode override attempts blocked | 100% | Pilot must escalate to human in autonomous; auto-overrides are a bug |

## 4. Dogfood outcomes (per D-041)

oh-my-tbd is developed under its own discipline. v0 ships only after **one full sprint** with:

- All commits respect batch-size caps (or override-with-reason logged)
- All feature work behind flags (or override-with-reason logged)
- Divergence cap respected (per D-050)
- Veto/override patterns retro'd weekly
- Adversarial-corpus regression suite passing on every change to navigator prompt or principle files

**Concrete dogfood milestones:**

- [ ] Walking skeleton built using only walking-skeleton discipline
- [ ] First navigator veto raised on the project's own code
- [ ] First human override on the project's own code (with reason captured)
- [ ] First retro using `/tbd:retro` on the project's own dissent log

## 5. External A/B story

Before broad publish:

- [ ] One external repo (not author's) runs oh-my-tbd for a sprint
- [ ] Measured baseline: defect rate, integration cadence (commits/day to trunk), override count
- [ ] Comparative: same team's prior sprint without oh-my-tbd
- [ ] Story documented in this file's "Calibration log" section

**Caveat:** a single external project is existence proof, not proof of generalisability. v0 publish acknowledges this explicitly in the README.

## 6. Calibration log

(Reserved for empirical numbers as telemetry accumulates.)

| Date | Cohort | Sessions | Median vetoes/session | Override % | Adversarial detect % | Notes |
|---|---|---|---|---|---|---|
| | | | | | | |

## 7. Risks to validity

- **Single dogfood project is not generalisable.** Author bias toward designs that pass their own discipline.
- **Adversarial corpus quality is itself unmeasured.** A corpus that misses real-world violation patterns gives false confidence.
- **"Open to all practitioners" (D-001) is aspirational** — v0 is CC-only (D-042). Generalisation to other tools is unvalidated.
- **Cost stance** (D-009 — cost not a constraint) is unmeasured in dogfooding. Need to track token spend per session and surface in retros; if pairing cost exceeds genuine quality lift, the stance needs revisiting.
- **TBD's own evidence base** is biased toward teams that adopted it because they were already inclined to discipline. Whether oh-my-tbd helps teams that *aren't* so inclined is unknown.

## 8. What we explicitly do NOT measure in v0

- Long-term codebase health (months to years; out of scope)
- Cross-repo generalisation (requires N projects; out of scope)
- Team-scale dynamics (more than 2-3 humans; out of scope)
- Cost per LOC produced (would need attribution heuristic; out of scope)

These are noted so v1 success doesn't quietly creep into "v0 promises that were never made."

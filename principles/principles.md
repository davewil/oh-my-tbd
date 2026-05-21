# oh-my-tbd — Principles Reference

Reference reading on the practices the pilot operates under. This file is no longer a runtime rubric — there is no navigator that reads it before every action, no `veto.json` machinery, no adversarial-corpus regression suite. Post-reset, this file exists as coaching material for the pilot and for any human curious about the underlying practice.

The pilot prompt ([agents/pilot.md](../agents/pilot.md)) carries the load-bearing summary. This file unpacks the same practices with concrete violation patterns and recovery moves.

---

## TBD — Trunk-Based Development

### Trunk-divergence

Divergence from trunk is debt. Three sources count, and the largest is what matters:

- Named branch age since merge-base with trunk
- Age of oldest uncommitted change in the working tree
- Age of oldest stash entry

**Watch for:** divergence creeping up before starting a new work unit; long-lived feature branches; "I'll commit after one more thing" patterns that compound.

**Recovery:** integrate to trunk (commit + push, or open PR for merge) before further work. The smallest shippable subset goes first; the rest follows as separate commits.

### Small batches

Each commit makes one declarable change. Bundling is the dominant defect correlate in trunk-based work — it makes review hard, rollback coarse, and bisect useless.

**Watch for:**
- Refactor + new feature in one diff
- Two distinct features in one diff
- Feature + unrelated bug fix in one diff
- Drive-by formatting changes mixed into a substantive diff
- "While I was in here, I also..." anywhere in the rationale

**Recovery:** split into separate commits, each with its own declared intent. If you've already done the work, `git reset --soft` to lift the changes off HEAD and re-stage in batches.

### Integration cadence

Frequent integration is the practice that makes TBD viable. Multi-day accumulations defeat its risk model.

**Watch for:** a commit representing work that should have integrated days ago; defers of integration that is now possible; "I'll integrate after I get this one piece right" loops.

**Recovery:** integrate the smallest shippable subset first; defer the rest to a follow-up commit.

### Expand-contract

Schema migrations are expand-then-contract across separate commits:

1. **Expand:** add the new shape; readers tolerate both old and new.
2. **Cut over:** writers move to the new shape.
3. **Contract:** remove the old shape.

Each phase is a separate commit. Combined add+remove in one commit breaks rollback safety.

**Watch for:** a migration that drops a column / table / field in the same commit it adds the replacement.

**Recovery:** split into expand and contract commits, ideally separated by a deploy cycle.

---

## XP — Extreme Programming

### Test-first (TDD)

Production code changes follow a failing test. New behaviour: test first. Bug fix: regression test first.

**Watch for:**
- New function or method with no test that exercises it
- A behavioural change in production code with no corresponding test change
- A bug fix landing without a regression test

**Exception:** a declared refactor doesn't add new tests — but the existing suite must cover the changed paths and pass unchanged. That's the `behaviour-preservation` discipline below, which is stricter than test-first, not laxer.

**Recovery:** write the failing test first, then make the production change to turn it green.

### YAGNI

You aren't gonna need it. Code added for hypothetical future requirements is waste — cognitive load, maintenance, attack surface — with no caller justifying it now.

**Watch for:**
- New configuration option with no caller
- Abstract base class with one implementation
- Function parameter "in case we need to..." with no current use
- Branch in code "for when X happens" with no current X
- A library dependency added for one not-yet-needed capability

**Recovery:** delete the speculation. Add it back when the third concrete need appears.

### Simple design

Premature abstraction is worse than three similar lines. Kent Beck's rules apply — passes tests, reveals intent, no duplication, fewest elements. "Fewest elements" is the one most often violated.

**Watch for:**
- New abstraction introduced for fewer than three concrete uses
- Strategy / Factory / Builder applied to one variant
- Generic type / interface introduced for one implementation
- Premature dependency injection where direct construction would do

**Recovery:** inline the abstraction. Restore it when the third concrete instance appears and the duplication has actually become a maintenance problem.

### Behaviour preservation (refactor discipline)

Applies when the declared work-unit type is `refactor`. A pure refactor changes structure without changing observable behaviour. The contract: the test suite as it stood before the refactor passes unchanged after.

**Watch for:**
- Assertion changed in any test in the same diff
- Test deleted in the same diff
- New branch in production code (refactors don't add branches; they reshape existing ones)
- Public API signature changed
- Behaviour-visible side effect added or removed (logs that contracts depend on, exception types narrowed/widened)

**Recovery:** if behaviour really must change, re-declare the intent as `feature` or `fix` and write a test that captures the change.

### Continuous integration (honest commit messages)

Commits integrate working software. Bare or evasive commit messages defeat that.

**Watch for:**
- `wip`, `fix`, `stuff`, `more`, `update`, `temp`, `.` as the entire message
- Message that does not name the changed surface ("fix bug" without naming what bug)
- Message that promises the next commit ("part 1 of N" without N being declared)

**Recovery:** write a one-line subject + optional body. Subject names the change; body names the why and which tests pass.

---

## LEAN — Lean Software Development

### Build quality in

Tests are run, not just written. A commit on hope is a commit that didn't run the tests.

**Watch for:** committing without running the test suite for the changed area; relying on "I'll catch it in CI"; running only one test for a change that touches three.

**Recovery:** run the tests. If they pass, commit. If they fail, the commit is the wrong action — fix or revert.

### Amplify learning

Recurring overrides on the same principle indicate a rule that needs revision, not a bypass to repeat. If the pair (or the human) raises the same objection three times across a session and you override each time, the rule itself is wrong for this context — or you are, but reflexively rather than reasoning.

**Watch for:** the same objection arising repeatedly with the same brush-off; principles being treated as friction to bypass rather than evidence to engage with.

**Recovery:** halt the work unit. Sit with the pattern. Either accept the principle (the pair is right and you've been wrong), tighten it (the principle is right but the language is unclear), or document a project-specific exception (the principle genuinely doesn't fit *this* project and we're going to be honest about that).

### Eliminate waste

Dead code is waste even if it does no immediate harm — it confuses readers, hides defects, and weights every refactor.

**Watch for:**
- New function with no callers (and not exported as public API)
- Branch in code that no test exercises and no caller reaches
- Commented-out block more than one line
- Imports / dependencies retained "in case"
- Configuration values read from but never set, or set but never read

**Recovery:** delete the dead code. If the deletion is risky, do it as a separate `refactor` commit so its blast radius is isolated.

---

## Feature-flag posture

The pilot prompt frames the working rule: new feature work typically lands behind a flag if the surface is user-visible. The flag registry lives at `.tbd/flags.yaml` (see [SCHEMAS.md](../SCHEMAS.md)).

The post-reset plugin does not mechanically check for missing flags — that classification was rubric-as-code, deleted in the session-9 reset. The discipline now lives in the pilot's judgement and the pair's voice. Two practical heuristics worth preserving:

- **Migrations and deletions don't take the no-flag shortcut.** Even if a migration looks like additive-only at the schema layer, it changes runtime behaviour for every reader; flag the expand step separately from the contract step.
- **Test-only and docs-only diffs don't need flags.** The check is "does anything in production reach this code at runtime?" If no, no flag.

---

## What's no longer in this file

For readers comparing against an earlier draft: the non-interaction criterion (L0/L1/L2/L3 layers, language adapters, dynamic-wiring patterns), the skip-detection hook check, and the rubric-as-code framing ("Veto when / Veto remedy" with `pending-action.json` field references) were retired in the session-9 architectural reset. See the post-reset section of [DESIGN-LOG.md](../DESIGN-LOG.md) for what replaced them.

---

## Versioning

Version: **0.2.0 — post-reset reference reading.** The file is no longer load-bearing for runtime behaviour; it's coaching material. Changes to the pilot's actual practice are made in `agents/pilot.md`.

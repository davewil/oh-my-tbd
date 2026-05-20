# oh-my-tbd — Library Principles (v0)

The TBD / XP / LEAN checklist the navigator walks for every pending action. Project-level extensions live in `.tbd/principles-additions.md` (additive); project-specific contracts live in `.tbd/invariants.md`.

Per D-007: every veto cites the principle being upheld. Principle names here are the canonical `principle` field values for `.tbd/veto.json`. The `principle_source` field uses one of `TBD | XP | LEAN | project-invariants | principles-additions`.

Per D-022 precedence: this file (library) < `~/.tbd/principles-additions.md` (user) < `.tbd/principles-additions.md` (project). Additions stack; project files cannot remove a library principle, only add or constrain.

---

## TBD — Trunk-Based Development

### `trunk-divergence`

**Source:** TBD. **Cite as:** `TBD/trunk-divergence`.

Divergence from trunk is debt. The cap (`.tbd/config.yaml: trunk.divergence_cap.max_hours`) applies to whichever divergence source is largest (D-050):

- Named branch age since merge-base with trunk
- Age of oldest uncommitted change in the working tree
- Age of oldest stash entry

**Veto when:** the proposed action would push current divergence beyond the cap, OR divergence is already over cap and the action does not reduce it.

**Veto remedy:** integrate to trunk (commit + push, or open PR for merge) before further work.

### `small-batches`

**Source:** TBD. **Cite as:** `TBD/small-batches`.

Each commit makes one declarable change. Bundling is the dominant defect-correlate in trunk-based work — it makes review hard, rollback coarse, and bisect useless.

**Veto patterns:**
- Refactor + new feature in one diff
- Two distinct features in one diff
- Feature + unrelated bug fix in one diff
- Drive-by formatting changes mixed into a substantive diff
- "While I was in here, I also..." anywhere in the rationale

**Veto remedy:** split into separate commits, each with its own declared intent.

### `integration-cadence`

**Source:** TBD. **Cite as:** `TBD/integration-cadence`.

Frequent integration is the practice that makes TBD viable. Multi-day accumulations defeat its risk model.

**Veto when:** a commit represents work that should have integrated days ago, OR the action defers an integration that is now possible.

**Veto remedy:** integrate the smallest shippable subset first; defer the rest to a follow-up commit.

### `expand-contract`

**Source:** TBD. **Cite as:** `TBD/expand-contract`.

Schema migrations are expand-then-contract across separate commits:

1. **Expand:** add the new shape; readers tolerate both old and new.
2. **Cut over:** writers move to the new shape.
3. **Contract:** remove the old shape.

Each phase is a separate commit. Combined add+remove in one commit breaks rollback safety.

**Veto when:** a migration drops a column / table / field the same commit it adds the replacement.

**Veto remedy:** split into expand and contract commits, ideally separated by a deploy cycle.

---

## XP — Extreme Programming

### `tdd`

**Source:** XP. **Cite as:** `XP/tdd`.

Production code changes follow a failing test. Per D-012 the navigator upholds TDD by checklist (no separate mechanical TDD hook in v0).

**Veto when:**
- New function or method exists without a test that exercises it
- A behavioural change appears in production code with no corresponding test change
- A bug fix lands without a regression test

**Exception:** `current-intent.json.type == "refactor"` exempts the diff from new-test-required, but raises `behaviour-preservation` instead (which is *stricter* — the test suite must already cover the changed paths and pass unchanged).

**Veto remedy:** write the failing test first, then re-propose the production change.

### `yagni`

**Source:** XP. **Cite as:** `XP/yagni`.

You aren't gonna need it. Code added for hypothetical future requirements is waste — it has cost (cognitive load, maintenance, attack surface) without benefit (no caller justifies it now).

**Veto patterns:**
- New configuration option with no caller
- Abstract base class with one implementation
- Function parameter "in case we need to..." with no current caller using it
- Branch in code "for when X happens" with no current X
- A library dependency added for one not-yet-needed capability

**Veto remedy:** delete the speculation. Add it back when the third concrete need appears.

### `simple-design`

**Source:** XP. **Cite as:** `XP/simple-design`.

Premature abstraction is worse than three similar lines. Kent Beck's rules (passes tests, reveals intent, no duplication, fewest elements) apply; "fewest elements" is the one most often violated.

**Veto patterns:**
- New abstraction introduced for fewer than three concrete uses
- Strategy / Factory / Builder applied to one variant
- Generic type / interface introduced for one implementation
- Premature dependency injection where direct construction would do

**Veto remedy:** inline the abstraction. Restore it when the third concrete instance appears and the duplication has actually become a maintenance problem.

### `behaviour-preservation`

**Source:** XP. **Cite as:** `XP/behaviour-preservation`. Applies only when `current-intent.json.type == "refactor"`.

A pure refactor changes structure without changing observable behaviour. The contract is: the test suite as it stood before the refactor passes unchanged after.

**Veto patterns:**
- Assertion changed in any test in the same diff
- Test deleted in the same diff
- New branch in production code (refactors don't add branches; they reshape existing ones)
- Public API signature changed
- Behaviour-visible side effect added or removed (logs that contracts depend on, exception types narrowed/widened)

**Veto remedy:** if behaviour really must change, redeclare intent as `feature` or `fix` and write a test that captures the change.

### `continuous-integration`

**Source:** XP. **Cite as:** `XP/continuous-integration`.

Commits integrate working software. Bare or evasive commit messages defeat that.

**Veto patterns:**
- `wip`, `fix`, `stuff`, `more`, `update`, `temp`, `.` as the entire message
- Message that does not name the changed surface ("fix bug" without naming what bug)
- Message that promises the next commit ("part 1 of N" without N being declared)

**Veto remedy:** write a one-line subject + optional body. Subject names the change; body names the why.

---

## LEAN — Lean Software Development

### `build-quality-in`

**Source:** LEAN. **Cite as:** `LEAN/build-quality-in`.

Tests are run, not just written. A commit without recent test-run evidence in `.tbd/action-trace.jsonl` is a commit on hope.

**Veto when:** `pending-action.json.tool == "Bash"` and `intent_str` is a commit AND no test-run entry appears in `action-trace.jsonl` since the most recent code change in the diff.

**Veto remedy:** run the tests. If they pass, re-propose. If they fail, the commit is the wrong action.

### `amplify-learning`

**Source:** LEAN. **Cite as:** `LEAN/amplify-learning`.

Recurring overrides on the same principle indicate a rule that needs revision, not a bypass to repeat. The dissent log surfaces patterns; this principle authorises the navigator to raise a meta-veto when the pattern is unmistakable.

**Veto when:** `dissent-log.jsonl` shows the same principle vetoed-then-overridden 3+ times in the current session.

**Veto remedy:** halt the work unit. The human reviews the override pattern in `/oh-my-tbd:retro` and either tightens the rule (project-level addition), loosens it (rare; project-level config override), or accepts the principle is genuinely contested in this project (document in `.tbd/invariants.md`).

### `eliminate-waste`

**Source:** LEAN. **Cite as:** `LEAN/eliminate-waste`.

Dead code is waste even if it does no immediate harm — it confuses readers, hides defects, and weights every refactor.

**Veto patterns:**
- New function with no callers (and not exported as public API)
- Branch in code that no test exercises and no caller reaches
- Commented-out block more than one line
- Imports / dependencies retained "in case"
- Configuration values read from but never set, or set but never read

**Veto remedy:** delete the dead code. If the deletion is risky, declare it as a separate `refactor` commit so its blast radius is isolated.

---

## Feature-flag policy

Per D-004: all new feature work lands behind a flag, unless verifiably non-interacting with existing code. Per D-029: migrations and deletions never qualify for the no-flag exception.

### `feature-flag-required`

**Source:** TBD (via `flags.yaml` policy). **Cite as:** `TBD/feature-flag-required`.

**Veto when:** `current-intent.json.type == "feature"` AND `flag_name` is absent or `null` AND non-interaction is not provable (see `non-interaction-criterion` below).

**Veto remedy:** register a flag in `.tbd/flags.yaml`, wrap the new code path in a flag check, and re-propose.

### `flag-call-site-registered`

**Source:** TBD (via `flags.yaml` policy). **Cite as:** `TBD/flag-call-site-registered`.

**Veto when:** the diff adds a flag check for `<flag>` AND `.tbd/flags.yaml` does not list `<flag>` with a `call_sites` entry pointing at the file/line.

**Veto remedy:** add the flag entry to `flags.yaml` (or update its `call_sites` list) in the same commit.

### `migration-no-flag-exception`

**Source:** TBD. **Cite as:** `TBD/migration-no-flag-exception`.

**Veto when:** the diff touches schema (migration files, DB DDL, ORM model definitions that drive migrations) OR removes code that is reachable from any entry point in `entry-points.yaml`, AND `flag_name` is absent. Non-interaction layers do NOT exempt this.

**Veto remedy:** flag the migration (expand step behind a flag; cut-over behind a separate flag; contract step behind a third flag if necessary) OR perform under formal change-management with explicit human override.

---

## Non-interaction criterion (the no-flag exception, per D-004 + D-027)

Layered. A diff qualifies for the no-flag exception only if all applicable layers clear it. Per D-027 conservative bias: when a layer is unavailable for the language and dynamic-wiring patterns are present, the answer is refuse.

### `l0-additive-only`

**Source:** TBD. **Cite as:** `TBD/l0-additive-only`.

**Veto when:** the diff modifies any existing file (vs. only adding new ones). Modification means insertion or deletion within a pre-existing file.

**Veto remedy:** either accept the flag requirement (modifications can interact) OR isolate the new code to new files.

### `l1-lexical-isolation`

**Source:** TBD. **Cite as:** `TBD/l1-lexical-isolation`.

**Veto when:** any symbol introduced in the new files appears (as identifier, string reference, decorator, or import path) anywhere in pre-existing files in the repo.

**Veto remedy:** rename to avoid collision OR accept the flag requirement.

### `l2-reachability`

**Source:** TBD. **Cite as:** `TBD/l2-reachability`. Requires a language adapter (see `adapters/` — Python, TypeScript, Go, C#, Elixir in v1 per D-028).

**Veto when:** the language adapter reports any new symbol reachable from any entry point declared in `.tbd/entry-points.yaml`.

**Veto remedy:** accept the flag requirement (the code is actually wired in).

### `dynamic-wiring-no-l2`

**Source:** TBD. **Cite as:** `TBD/dynamic-wiring-no-l2`.

**Veto when:** the diff contains dynamic-dispatch patterns (decorators, `importlib`, plugin registries, reflection, dependency-injection containers) AND no L2 adapter is available for this language.

**Veto remedy:** accept the flag requirement. Dynamic wiring is the case L2 was designed to catch; without it the only safe answer is "flag it."

---

## Skip-detection (D-043)

### `skip-detection`

**Source:** TBD. **Cite as:** `TBD/skip-detection`. Raised by the veto-check hook, not the navigator — included here for completeness.

**Veto when:** a state-changing tool call (`Write`, `Edit`, `NotebookEdit`, mutating `Bash`) arrives at the hook with no matching `.tbd/pending-action.json` on disk.

**Veto remedy:** the pilot must declare intent (`/oh-my-tbd:start`) if no current intent exists, then write `.tbd/pending-action.json` describing the action, then invoke the navigator subagent, before the tool fires.

---

## What is NOT in this file

- **Project invariants** — go in `.tbd/invariants.md` (e.g. "all migrations expand/contract", "auth always goes through `verifyToken`").
- **Project-level principle additions** — go in `.tbd/principles-additions.md` (additive to this file).
- **Per-language reachability rules** — encoded in `adapters/<lang>/`; navigator invokes them via the L2 layer.
- **Override and exception management** — see `SCHEMAS.md §5` (`overrides.jsonl`).

---

## Versioning

This file is read by the navigator at every review. Changes here change the navigator's behaviour repo-wide.

Per `VALIDATION.md §1` quality bar: any change to this file must pass the adversarial corpus regression suite (`corpus/`, per D-021) before shipping. Detection rate must remain ≥ 90% across all principle categories.

Version: **0.1.0 — walking-skeleton floor.** Subsequent revisions land via standard `oh-my-tbd` discipline (self-dogfood, D-041).

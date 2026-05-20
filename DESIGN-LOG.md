# TBD Customisation Suite — Design Log

Living document for the Trunk-Based Development customisation suite for Claude Code.
Captures pinned design decisions and open questions during the discussion phase.
Once implementation begins, major architectural commitments will split into ADRs.

- **Status:** discussion phase
- **Started:** 2026-05-19
- **Working dir:** `/Volumes/Personal/Users/davidwilliams/dev/trunk`
- **Cross-conversation context:** see `~/.claude/projects/-Volumes-Personal-Users-davidwilliams-dev-trunk/memory/`

---

## Pinned decisions

| ID | Date | Decision | Source |
|----|------|----------|--------|
| D-001 | 2026-05-19 | **Distribution scope:** published openly for any Claude Code practitioner; not just personal or team. | User |
| D-002 | 2026-05-19 | **Strictness model:** hard blocks; violations refuse the action and require explicit override. | User |
| D-003 | 2026-05-19 | **CI/CD posture:** working CI/CD is essential. Suite must guide setup on greenfield, describe gaps on brownfield. | User |
| D-004 | 2026-05-19 | **Feature flags by default:** all new feature work lands behind a flag, unless verifiably non-interacting with existing code (criterion still open — Q-002). | User rule #5 |
| D-005 | 2026-05-19 | **Standalone:** must function with OMC, nWave, and other plugins uninstalled. No dependencies on those ecosystems. | User |
| D-006 | 2026-05-19 | **Pairing is the default operating posture.** Review is realtime, in-flow. Async PR review is a degraded mode, not the norm. | User |
| D-007 | 2026-05-19 | **XP/LEAN principles are first-class and made visible** alongside TBD. Hooks, skills, and surfaces must name the principle being upheld or violated. | User |
| D-008 | 2026-05-19 | **Autonomous mode = pilot/navigator agent pair** with periodic role swap (mirroring XP pairing). | Proposed; accepted |
| D-009 | 2026-05-19 | **Cost is not a constraint.** Doubled token spend is acceptable; pays back through reduced rework (XP economic argument). | User |
| D-010 | 2026-05-19 | **Mob configurations supported:** 2 humans + 1 agent, 1 human + pilot/navigator pair, 2-agent autonomous pair. | User |
| D-011 | 2026-05-19 | **Navigator tool allowlist:** read tools (Read/Grep/Glob/read-only Bash) + restricted-write strictly limited to `.tbd/` audit paths. No code edits, no commits, no state-changing Bash. | User |
| D-012 | 2026-05-19 | **TDD upheld by navigator checklist:** failing test must exist before production code change. No separate mechanical TDD hook in v0. | User |
| D-013 | 2026-05-19 | **Default trunk model:** short-lived PR branches with hard lifetime cap (cap value open — Q-001). Direct-to-trunk is a configurable mode but not the default. | User-ratified |
| D-014 | 2026-05-19 | **Navigator veto is mechanical** via `.tbd/veto.json`. Pilot's PreToolUse hook reads it and refuses state-changing actions while a standing veto exists. | User-ratified |
| D-015 | 2026-05-19 | **Navigator invocation default:** synchronous hook-driven (option A — pilot writes pending action, navigator decides, pilot reads verdict). Periodic-checkpoint (option C) available as fast mode for high-trust tasks. | User-ratified |
| D-016 | 2026-05-19 | **Refusal messages name the principle.** Every block cites which TBD/XP/LEAN principle is being upheld. | User-ratified |
| D-017 | 2026-05-19 | **Handoff artifact at every role swap** (`.tbd/handoff-<n>.json`) — captures goal, test state, last commit, open questions, decisions, uncertainties, principles under pressure. | User-ratified |
| D-018 | 2026-05-19 | **Dissent log is the Kaizen surface.** `.tbd/dissent-log.jsonl` is append-only and feeds session retrospectives. | User-ratified |
| D-019 | 2026-05-19 | **Model effort tiers** — `low` (Sonnet nav + Haiku pilot), `standard` (Opus nav + Sonnet pilot, default), `high` (Opus both). Cross-vendor is a future enrichment. | User |
| D-020 | 2026-05-19 | **Navigator is blind to task spec and pilot reasoning by default**, but may ask the pilot narrowly-scoped clarifying questions via a structured channel (`.tbd/navigator-questions.jsonl` → `.tbd/pilot-responses.jsonl`). Pilot must respond before the next state-changing action. | User |
| D-021 | 2026-05-19 | **Suite ships with an adversarial test corpus** — known-bad diffs covering each TBD/XP/LEAN principle. Acts as the navigator's regression suite and a quality bar for prompt changes. | User |
| D-022 | 2026-05-19 | **Principle / invariant file precedence:** library defaults < user-level (`~/.tbd/`) < project-level (`.tbd/`). Additions stack; overrides replace. | User |
| D-023 | 2026-05-19 | **Asymmetric prompts** — pilot is balanced toward action; navigator is deliberately adversarial ("default to vetoing; rubber-stamping is the failure mode"). | User-ratified (implicit via Q-013/14 acceptance) |
| D-024 | 2026-05-19 | **Context isolation as primary independence lever** — navigator sees only diff + principles + invariants + dissent log + pending action. No conversation history, no spec, no pilot reasoning traces. | User |
| D-025 | 2026-05-19 | **Measurement is first-class.** Navigator health tracked via veto rate, principle diversity of vetoes, human-override rate, adversarial-corpus detection rate. Surfaced in retros. | User-ratified |
| D-026 | 2026-05-19 | **Clarifying-question channel constraints:** citation-required; narrow-scope (about the change, not the intent); per-veto budget = 3; per-session budget = 12 with escalation; pilot answers narrowly; no inverse channel (pilot cannot ask navigator for advance approval). | User |
| D-027 | 2026-05-19 | **Non-interaction criterion is layered.** L0 (additive-only) + L1 (lexical isolation) + optional L2 (per-language reachability) + on-demand L3 (runtime confirmation). Conservative bias: dynamic-wiring patterns without L2 → exception refused. | User-ratified |
| D-033 | 2026-05-19 | **Pilot explicitly invokes navigator via the Agent tool**, not hooks. Pilot is the main session; navigator is a subagent invoked synchronously before state-changing actions. The Agent tool is in the pilot's allowed-tools list. **Supersedes D-015.** | User; verified against Claude Code primary docs |
| D-034 | 2026-05-19 | **Hooks are pure backstop / verification.** PreToolUse hooks: read `.tbd/veto.json` (refuse if standing), check skip-detection (refuse if no recent navigator-review entry for current pending-action), apply mechanical limits (batch size, divergence cap). Triggering is the pilot's responsibility, not the hook layer. **Refines D-014.** | User |
| D-035 | 2026-05-19 | **Role-swap mechanics in v0:** fixed pilot/navigator agents in autonomous mode (no mechanical swap). Conceptual XP-swap is reserved for paired-mode where a human can take either role. Revisit after thorough dogfooding. | User |
| D-036 | 2026-05-19 | **Experimental agent hooks (60s yes/no) used for short mechanical checks** — L0 (additive-only), L1 (lexical isolation), divergence-cap. Not used for full navigator review. | Proposed |
| D-037 | 2026-05-19 | **Hooks are thin shell invocations of a single Node.js CLI** shipped at `bin/tbd.js`. Command form: `node ${CLAUDE_PLUGIN_ROOT}/bin/tbd.js hook <name>`. | User |
| D-038 | 2026-05-19 | **CLI implementation: TypeScript → JavaScript.** Source in `src/`; compiled output in `bin/`. | User |
| D-039 | 2026-05-19 | **Minimum-dependency posture.** Built-in Node modules where feasible. One JSON-schema validator (ajv) acceptable. | User |
| D-040 | 2026-05-19 | **`.tbd/` schema and state machine pinned** — see `SCHEMAS.md`. JSON Schema files ship in plugin and validate on read; malformed files trigger hard-block. | Proposed |
| D-041 | 2026-05-19 | **Self-dogfood mandate.** oh-my-tbd is developed under its own discipline from commit #1 — flag-gated feature work, batch-size caps, divergence-cap caps, navigator vetoes, override audit. The project is its first user. | User |
| D-042 | 2026-05-19 | **v0 scoped as Claude-Code reference implementation.** "Open to all practitioners" (D-001) remains the long-term ambition; v0 ships a CC-only plugin. Explicit commitment to factor out an IDE-agnostic `tbd-core` after one working integration exists. | User |
| D-043 | 2026-05-19 | **Skip-detection pin.** State-changing tool calls (Write, Edit, NotebookEdit, Bash matching a state-mutating allowlist) require a matching `pending-action.json` to exist. "Match" = hash of `(tool_name + canonicalised_args)`. Missing pending-action = hard refuse with explicit message. Read/Grep/Glob bypass. | User |
| D-044 | 2026-05-19 | **Walking skeleton cut to minimum loop:** 5 schemas (`current-intent`, `pending-action`, `veto`, `dissent-log`, `session-state`) + 1 hook (`tbd-veto-check` with skip-detection) + 2 agents (pilot, navigator) + 2 skills (`/tbd:start`, `/tbd:override`). Everything else is enrichment built on top. | User |
| D-045 | 2026-05-19 | **Working name: `oh-my-tbd`.** Riff on oh-my-zsh / oh-my-claudecode. Final name confirmed at publish. | User |
| D-046 | 2026-05-19 | **Plugin spec verified against primary docs.** Manifest at `.claude-plugin/plugin.json`. Components at plugin root: `agents/`, `hooks/`, `skills/`, `bin/`, `commands/` (legacy). Hooks in `hooks/hooks.json`. Env: `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_DATA}`. | Primary-source verified |
| D-047 | 2026-05-19 | **Hook invocation uses exec form, not shell.** `{"type":"command", "command":"node", "args":["${CLAUDE_PLUGIN_ROOT}/bin/tbd.js", "hook", "<name>"]}`. No shell involvement → cross-platform clean. **Refines D-037.** | Primary-source verified |
| D-048 | 2026-05-19 | **Veto refusal uses JSON output, not exit codes.** PreToolUse hook returns `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<navigator-reason-cited>"}}`. Richer than exit 2 + stderr. | Primary-source verified |
| D-049 | 2026-05-19 | **Pilot activated as main thread via `settings.json`.** Plugin ships `settings.json` with `{"agent":"pilot"}` so enabling the plugin makes the pilot persona the default main agent. Users don't need to explicitly invoke pilot. | Primary-source verified |
| D-036 | 2026-05-19 | **Risk log:** D-036 depends on experimental agent-hook type. **Backup path:** L0/L1/divergence-cap revert to regular command hooks calling `tbd <check>` if the experimental type is removed/changed. ~80ms additional cold start per check; no behaviour change. | Risk-logged |
| D-050 | 2026-05-20 | **Divergence is the primitive, not "branch."** TBD discipline is "keep divergence from trunk small and short-lived." Divergence sources: (a) named branch age since merge-base with trunk, (b) age of oldest uncommitted change in working tree, (c) age of oldest stash entry. Whichever is largest = current divergence age. Cap applies to that. Branch-vs-direct-to-trunk is a UX choice, not a discipline choice — both are micro-divergence by another name. **Supersedes D-013.** | User |
| D-051 | 2026-05-20 | **`.tbd/` writes bypass the veto-check hook (orchestration substrate carve-out).** Any state-changing tool call whose primary target is inside `.tbd/` is permitted by the hook without `pending-action.json.tool` matching. Rationale: the navigator's veto, dissent-log, and question-channel files are the discipline's own substrate; gating them by pending-action creates recursion. **Empirically discovered 2026-05-20 dogfood session** — navigator could not append its own `veto_lifted` trace entry (forced pilot trace-close) and could not Bash-read `.tbd/` to verify diffs (forced trust on `diff_summary`). Implementation: separate work unit after walking-skeleton commits land. | Dogfood-surfaced |
| D-052 | 2026-05-20 | **`pending-action.json` is single-shot.** After a state-changing call matches and passes the hook, the hook archives `.tbd/pending-action.json` to `.tbd/archive/<session>/` (or marks `consumed: true`). Subsequent state-changing calls require a fresh pending-action — re-asserts D-043 skip-detection per-action. Without consumption tracking, a stale pending-action could permit multiple unrelated actions silently. **Empirically discovered 2026-05-20 dogfood session** — stale pa-2026-05-20-001 remained after clear, leading to a procedural skip-detection veto on pa-2026-05-20-002. Implementation: separate work unit after walking-skeleton commits land. | Dogfood-surfaced |
| D-053 | 2026-05-20 | **Discipline is a baseline, not doctrine** (XP/LEAN: process serves people; eliminate waste). Hard blocks are reserved for substantive risk: untested production code, unflagged user-facing work touching live paths, oversized batches that resist bisect/revert, broken trunk (stop-the-line), self-approval without independent review. Procedural drift (stale pa, line-count mismatch in diff_summary, trace gaps, exact tool-name matching on substrate updates) is surfaced as a warning or logged for review, not refused. When in doubt, pilot/navigator pragmatism over recursive process overhead. Calibration is empirical: if a class of veto repeatedly catches non-issues, it gets softened; if a class repeatedly misses real issues, it gets tightened. **Empirically motivated by first dogfood session** — ~30% of navigator interactions caught real risk (e.g., pa-004 TDD veto), ~70% were procedural noise from D-051/D-052 not yet implemented. The umbrella under which D-054 and D-055 candidates (and future calibration adjustments) operate. | User |
| D-028 | 2026-05-19 | **L2 reachability adapters shipped in v1:** Python, TypeScript, Go, C#, Elixir. Adapter strength varies (Go/Rust/Java/C#/TS strong; Python moderate; Elixir backed by `mix xref` plus framework-pattern exclusions). Other languages fall back to L0+L1+pattern-exclusion. Adapter API is extensible — community/projects can add adapters. | User |
| D-029 | 2026-05-19 | **Migrations and deletions never qualify for the no-flag exception**, regardless of layer outcomes. Always expand/contract for schema; deletions handled as refactor commits. | User-ratified |
| D-030 | 2026-05-19 | **Test-only and docs-only diffs are exempt** from the flag requirement, subject to a "no production-path touches" check. | User-ratified |
| D-031 | 2026-05-19 | **Pure refactors are a distinct commit category**, not handled via the non-interaction criterion. Navigator verifies behaviour preservation. Mechanism TBD (Q-019). | User-ratified |
| D-032 | 2026-05-19 | **Project entry points declared in `.tbd/entry-points.yaml`**, bootstrapped by auto-detect on first run with human confirmation. | User-ratified |

## Open questions

| ID | Question | Status | Leaning / notes |
|----|----------|--------|-----------------|
| Q-001 | What are the divergence cap values across all three sources (max divergence age in hours; max commits on named branch since merge-base; max files changed total — uncommitted + branch commits)? | open | Per D-050, cap applies to divergence age regardless of source. Likely defaults: 24h, 10 commits, 50 files; tunable in `.tbd/config.yaml` |
| Q-002 | What is the criterion for "verifiably non-interacting" code? (D-004 loophole) | open | Candidates: new files only / no imports from existing / no reachability from entry points / static-analysis-proven. Strongest variants need per-language adapters |
| Q-003 | Override mechanism details — paired path vs autonomous path | open | Paired likely `/tbd:override <reason>`; autonomous likely navigator concurrence + human notification + audit |
| Q-004 | Visibility surface medium — slash command, status file, statusline, all? | open | |
| Q-005 | Veto inheritance on role swap — carry over, expire, review-afresh? | deferred | User asked to come back to |
| Q-006 | Engineered-difference levers between pilot and navigator | open | Levers: prompts (cheap), models (cost), context isolation, specialisation. Minimum probably prompts + context isolation |
| Q-007 | Autonomous-mode detection signals — env var, TTY, parent process? | open | Layered approach proposed |
| Q-008 | Feature flag library policy — mandate / recommend / accept-any / ship minimal? | open | |
| Q-009 | Stop-the-line propagation scope in v1 | open | Broken trunk halts new feature work; how broadly? |
| Q-010 | Conventional commits as ground truth for intent classification | open | Discussed but not committed |
| Q-011 | TDD strictness in paired mode — coach-only or upheld mechanically? | leaning coach | Pilot/navigator handles autonomous |
| Q-017 | How are clarifying questions constrained to preserve navigator independence? (citation-required? narrow-scope? per-veto budget?) | open | Without constraint, navigator can effectively read the spec by enumeration |
| Q-018 | Concrete per-language dynamic-wiring pattern lists (what triggers "L2 unavailable + dynamic pattern → refuse") | open | Per-language work; can be done alongside adapter implementation |
| Q-019 | Refactor commit category — navigator's behaviour-preservation check (property tests? test-suite invariance? mutation testing?) | open | Important enough to be its own dimension before v1 ships |
| Q-020 | Cross-platform hook implementation language — Bash / Python / Node? | open | Surfaced by component sketch; affects Windows support |
| Q-021 | Claude Code statusline coexistence — how to avoid conflict with user's existing statusline? | open | Surfaced by component sketch |
| Q-022 | Plugin manifest format — verify against current Claude Code plugin spec | open | Needs primary-source check before P7 |
| Q-023 | Navigator-review synchronous agent invocation — feasibility via current Claude Code primitives | open | Critical feasibility question for P3 |
| Q-024 | `entry-points.yaml` auto-detection — per-framework heuristics? | open | Surfaced by component sketch |
| Q-025 | Storage / rotation policy for `.tbd/action-trace.jsonl` in long-running projects | open | Surfaced by component sketch |
| Q-026 | Role-swap mechanics under pilot-is-main model | Resolved 2026-05-19 — see D-035 (fixed agents in autonomous mode for v0) |
| Q-027 | Beyond the items in D-036, what other mechanical checks fit the experimental agent-hook (60s yes/no) shape? | open | Inventory of agent-hook-suitable checks |
| Q-033 | D-054 candidate: should `pending-action.json` be advisory at the hook layer (skip-detection only — pa must exist) and contractual at the navigator layer (navigator catches tool/scope divergence in review)? | open | Per D-053. Removes ~80% of session-1 procedural friction. Trade-off: looser hook means worse skip-detection backstop if navigator review is skipped or cursory |
| Q-034 | D-055 candidate: should D-052 (consumption tracking) soften to "archive consumed pa on success" without using staleness as a refusal predicate? Stale pa becomes a warning at next review; does not block. | open | Per D-053. Consumption tracking still useful for audit; just not load-bearing for refusal |

## Decisions superseded

| ID | Original | Superseded by | When | Why |
|----|----------|---------------|------|-----|
| D-015 | Synchronous hook-driven navigator invocation (Option A) | D-033 | 2026-05-19 | Claude Code hooks cannot multi-turn-invoke subagents. Pilot must invoke navigator directly via Agent tool. |
| D-013 | "PR branches with hard lifetime cap as default trunk model" | D-050 | 2026-05-20 | "Branch" is a special case of divergence. The primitive is divergence age across all sources (branch + WIP + stash); branched vs. direct-to-trunk is a UX choice within that discipline. |

## Resolved questions

| ID | Question | Resolution |
|----|----------|------------|
| Q-012 | Confirm D-013 (PR branches as default) | Confirmed 2026-05-19 — see D-013 |
| Q-013 | Default model assignment | Resolved 2026-05-19 — see D-019 (effort tiers) |
| Q-014 | Navigator blind to task spec | Resolved 2026-05-19 — see D-020 (blind + clarifying-question channel) |
| Q-015 | Ship adversarial test corpus | Resolved 2026-05-19 — see D-021 |
| Q-016 | Principle file ownership model | Resolved 2026-05-19 — see D-022 (defaults + user + project, stack/override) |
| Q-017 | Clarifying-question constraints | Resolved 2026-05-19 — see D-026 |
| Q-023 | Navigator-review synchronous agent invocation feasibility | Resolved 2026-05-19 — feasible via Agent tool from pilot; see D-033 |

## Process notes

- This log is updated **every turn a decision lands or an issue opens**. If a turn closes without an update, that itself is an error worth flagging.
- Memory files in `~/.claude/projects/.../memory/` cover *semantic* / cross-conversation context. This file covers *running* design state.
- Decision IDs are stable; supersession is via explicit entry in the "Decisions superseded" section, not silent edit.

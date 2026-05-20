# Next-Session Continuation

Working notes for resuming after a session restart. Read this first, then jump into priority 1.

- **Last session ended:** 2026-05-20
- **State:** bootstrap scaffold complete; not yet committed (user decides). Plugin loadable but applies no discipline yet.
- **Repo:** `/Volumes/Personal/Users/davidwilliams/dev/trunk/`

---

## Where we are

- 49 pinned decisions, 1 explicit supersession (D-013 → D-050), 32 open/resolved questions.
- All four design docs current: `DESIGN-LOG.md`, `COMPONENTS.md`, `SCHEMAS.md`, `VALIDATION.md`.
- Git repo initialised on `main`. Bootstrap files written (plugin manifest, settings, stub agents, stub skills, hooks shell, CLI placeholder, README).
- Plugin loadable via `claude --plugin-dir .` — all stubs render cleanly; no checks wired in yet.
- Dogfood discipline (D-041) starts the moment the veto-check hook is real.

---

## What to do next (priority order)

### 1. Write the real `navigator.md` system prompt

**File:** `agents/navigator.md`
**References:** D-023 (asymmetric prompts), D-024 (context isolation), D-025 (measurement-first), D-026 (clarifying-question constraints), D-035 (fixed roles in v0).
**Why first:** the navigator is the load-bearing artefact. The pilot's prompt depends on knowing what the navigator will check.
**Key properties to encode:**
- Default to vetoing.
- See only diff + principles + invariants + dissent log + pending action.
- Adversarial framing: false vetoes are recoverable; rubber-stamping is the failure mode.
- Cite principle, evidence, remedy on every veto.
- Constrained question channel (D-026 budgets).

### 2. Write the real `pilot.md` system prompt

**File:** `agents/pilot.md`
**References:** D-023 (balanced toward action), D-033 (explicit navigator invocation), D-043 (skip-detection — pilot must write `pending-action.json` before state-changing calls).
**Key properties:**
- Bias toward action. Small commits. Frequent integration.
- Always declare intent via `/oh-my-tbd:start` before a work unit.
- Before any state-changing tool call: write `pending-action.json` (with hashed action), invoke `navigator` via Agent tool, read `veto.json`, address standing veto or proceed.
- Address vetoes, do not argue past them; if dispute is needed, use `dissent-log.jsonl`.

### 3. Implement `tbd hook veto-check` in `bin/tbd.js`

**File:** `bin/tbd.js`
**References:** D-014, D-034, D-043, D-048.
**Subcommand:** `tbd hook veto-check`
**Inputs:** reads `.tbd/veto.json`, `.tbd/pending-action.json`, hook input JSON on stdin (for the about-to-fire tool call).
**Behaviour:**
- If `pending-action.json` absent and incoming call is state-changing → return `permissionDecision: "deny"` with reason "declare via /oh-my-tbd:start and navigator-review flow first."
- If `veto.json` present with `status: standing` AND its `blocked_action_ref` hash matches the incoming hash → return `deny` with reason built from `principle / principle_source / reason / first remedy`.
- Otherwise → return `permissionDecision: "allow"`.
- Output format: JSON with `hookSpecificOutput.hookEventName: "PreToolUse"`, `permissionDecision`, `permissionDecisionReason`.

### 4. Wire the veto-check hook into `hooks/hooks.json`

**File:** `hooks/hooks.json`
**Reference:** D-047 exec form.

```json
{
  "description": "oh-my-tbd PreToolUse veto check (discipline backstop)",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node",
            "args": ["${CLAUDE_PLUGIN_ROOT}/bin/tbd.js", "hook", "veto-check"]
          }
        ]
      }
    ]
  }
}
```

### 5. Implement `/oh-my-tbd:start` and `/oh-my-tbd:override` skills

**Files:** `skills/start/SKILL.md`, `skills/override/SKILL.md`.
**Behaviour:** described in the stubs themselves.

### 6. Add `settings.json` activating pilot as main thread

**File:** `settings.json` (plugin root).
**Reference:** D-049.

```json
{ "agent": "pilot" }
```

Defer until pilot.md is real (priority 2) — activating an unfinished pilot as main thread would be confusing UX.

### 7. Author `principles/principles.md`

**File:** `principles/principles.md` (new directory).
**Content:** the TBD / XP / LEAN checklist the navigator walks. Anchored on `DESIGN-LOG.md` D-007 and the named principles cited across decisions.

---

## Open decisions to revisit during build

- **Q-018** (per-language dynamic-wiring patterns) — needed when L2 adapters land (P4-equivalent in the original phasing).
- **Q-019** (refactor behaviour-preservation check) — needed when the refactor commit category is implemented.
- **Q-029** (secret-redaction patterns in action-trace) — needed when action-trace lands.
- **Q-030** (schema migration policy on `version:` bump) — needed at the first version bump.
- **Q-031** (UUID vs timestamp+counter ID generation) — defer until team-mode is in scope.

---

## Files to read on resume (5-10 minutes total)

1. `README.md` — orient.
2. This file (`NEXT-SESSION.md`).
3. `DESIGN-LOG.md` § "Pinned decisions" — recent entries are D-041 → D-050.
4. `COMPONENTS.md` § "Walking skeleton" — the minimum loop you are building.
5. `SCHEMAS.md` § "Veto.json" + § "State machine" — load-bearing artefacts.

---

## Quick-resume commands

```bash
cd /Volumes/Personal/Users/davidwilliams/dev/trunk/
git log --oneline -5         # see where the bootstrap commit landed (if committed)
git status                   # see what's staged / dirty
node ./bin/tbd.js version    # smoke-test the CLI placeholder
claude --plugin-dir .        # load the plugin in dev mode
```

---

## A note on the bootstrap chicken-and-egg

Per D-041 (self-dogfood) and option (c) chosen at the last session: the project uses its own discipline as soon as the backstop is live. Priorities 1–4 above bring the minimum loop online. From priority 5 onward, the project's own commits are subject to the veto-check, the divergence cap, and so on — using oh-my-tbd to develop oh-my-tbd. Add a brief entry to `VALIDATION.md` §4 ("Dogfood outcomes") each time a milestone is hit.

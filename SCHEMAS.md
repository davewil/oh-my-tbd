# TBD Customisation Suite — `.tbd/` Schemas (v0)

The data contract for the filesystem-based message bus between pilot, navigator, hooks, and skills. Companion to `DESIGN-LOG.md` and `COMPONENTS.md`.

- **Status:** v0 draft
- **Started:** 2026-05-19
- **Format conventions:** YAML for human-edited config, JSON for transient state, JSONL for append-only logs, Markdown for human-readable surfaces. All files include a top-level `version` field on first write.

---

## 1. Directory layout

```
.tbd/                            # project-level state
├── config.yaml                  # project preferences (committed)
├── principles-additions.md      # project extensions to library principles (committed)
├── invariants.md                # project-specific contracts (committed)
├── entry-points.yaml            # declared user-facing entry points (committed)
├── flags.yaml                   # registered feature flags (committed)
│
├── current-intent.json          # current work-unit intent (gitignored)
├── session-state.json           # session metadata (gitignored)
├── pending-action.json          # pilot's proposed next state-change (gitignored)
├── veto.json                    # current standing veto or absent (gitignored)
│
├── navigator-questions.jsonl    # append-only Q channel, gitignored
├── pilot-responses.jsonl        # append-only A channel, gitignored
├── action-trace.jsonl           # append-only pilot actions, gitignored
├── dissent-log.jsonl            # append-only veto history, gitignored by default
├── overrides.jsonl              # append-only override audit, gitignored by default
│
├── handoff-<n>.json             # role-swap artifacts (n = session-local counter)
├── STATUS.md                    # regenerated; what other readers see
└── archive/<session-id>/        # rotated session files
```

User-level `~/.tbd/` mirrors `config.yaml` and `principles-additions.md` only. Library defaults ship in the plugin.

---

## 2. Configuration files (committed)

### `config.yaml`

```yaml
version: 1
effort_tier: standard            # low | standard | high (D-019)
default_mode: paired             # paired | autonomous

trunk:
  divergence_cap:                # applies to whichever divergence source is oldest (D-050)
    max_hours: 24                # caps named-branch age, uncommitted-WIP age, and stash age — whichever is largest
    max_commits_on_branch: 10    # branch commits since merge-base (only relevant if working on a named branch)
    max_files_changed_total: 50  # uncommitted + branch-committed-but-unintegrated combined

batch_size:
  max_lines_per_commit: 400
  max_files_per_commit: 10

flag_policy:
  require_flag_for: [feature]
  test_only_exempt: true
  docs_only_exempt: true

navigator:
  question_budget_per_veto: 3
  question_budget_per_session: 12
  invocation_mode: synchronous_per_action   # synchronous_per_action | checkpoint_on_commit (D-015 / D-033)

override:
  human_only_in_autonomous: true
  expires_after_action: true
  log_to: overrides.jsonl

retro:
  auto_run_on_session_end: true
```

Precedence: library defaults < `~/.tbd/config.yaml` < `.tbd/config.yaml`.

### `principles-additions.md`

Free-form markdown; appended to library `principles.md` at navigator load time. Project-specific items here.

### `invariants.md`

Free-form markdown; project-specific contracts (e.g., "all migrations are expand/contract", "auth always goes through `verifyToken`"). Navigator reads, checks diffs against these.

### `entry-points.yaml`

```yaml
version: 1
detected: true
last_audited: 2026-05-19T15:00:00Z

http_routes:
  - framework: fastapi
    glob: ["src/api/**/*.py"]
    detector_regex: "@router\\.(get|post|put|delete|patch)"

cli_commands:
  - framework: click
    symbols: ["src.cli:main"]

scheduled_jobs:
  - framework: celery
    detector_regex: "@app\\.task"

message_consumers:
  - framework: kafka-python
    symbols: ["src.workers:consume_orders"]

excluded_paths:
  - "tests/**"
  - "docs/**"
  - "**/migrations/**"
```

### `flags.yaml`

```yaml
version: 1
flag_system: growthbook          # none | growthbook | launchdarkly | unleash | configcat | custom
provider_config_ref: "https://..."   # optional, per-system

flags:
  oauth_v1:
    created: 2026-05-19
    created_for_intent: intent-2026-05-19-001
    status: active               # active | retiring | removed
    targeting_summary: "0% rollout — code path inactive"
    call_sites:
      - file: "src/auth/oauth.ts"
        line: 14
        function: "loginViaOAuth"
    owner: "auth-team"
    retire_by: 2026-08-19         # optional ISO date
```

---

## 3. Per-session state (gitignored)

### `session-state.json`

```json
{
  "version": 1,
  "session_id": "s-2026-05-19-001",
  "started_at": "2026-05-19T15:20:00Z",
  "mode": "paired",
  "mode_detection": {
    "tty_present": true,
    "env_autonomous": false,
    "parent_process": "claude"
  },
  "pilot_agent": "claude-sonnet-4-6",
  "navigator_agent": "claude-opus-4-7",
  "counts": {
    "swaps": 0,
    "vetoes_raised": 0,
    "vetoes_lifted": 0,
    "vetoes_escalated": 0,
    "overrides": 0,
    "questions_asked": 0
  }
}
```

### `current-intent.json`

```json
{
  "version": 1,
  "id": "intent-2026-05-19-001",
  "declared_at": "2026-05-19T15:23:00Z",
  "declared_by": "human",
  "type": "feature",
  "description": "Add OAuth login behind oauth_v1 flag",
  "flag_name": "oauth_v1",
  "expected_scope": {
    "files_touched_estimate": 8,
    "is_pure_refactor": false,
    "touches_migrations": false,
    "touches_entry_points": ["src/api/auth.ts"]
  }
}
```

`type` ∈ `feature | fix | refactor | chore | docs | test`.

---

## 4. Inter-agent coordination (gitignored, transient)

### `pending-action.json`

Written by pilot before invoking navigator.

```json
{
  "version": 1,
  "id": "pa-2026-05-19-014",
  "proposed_at": "2026-05-19T15:34:12Z",
  "tool": "Bash",
  "intent_str": "git commit -m 'feat: add OAuth provider behind oauth_v1 flag'",
  "diff_summary": {
    "files_changed": 6,
    "lines_added": 187,
    "lines_removed": 12,
    "files": ["src/auth/oauth.ts", "src/auth/oauth.test.ts"]
  },
  "intent_ref": "intent-2026-05-19-001"
}
```

### `veto.json`

Written by navigator. Absent file = no veto.

```json
{
  "version": 1,
  "id": "v-2026-05-19-001",
  "raised_at": "2026-05-19T15:34:30Z",
  "principle": "small-batches",
  "principle_source": "XP",
  "blocked_action_ref": "pa-2026-05-19-014",
  "reason": "Commit bundles refactor of session store with new OAuth feature.",
  "evidence": [
    {"file": "src/auth/session.ts", "lines": "12-45", "claim": "Pre-existing session functions modified — refactor"},
    {"file": "src/auth/oauth.ts", "lines": "1-160", "claim": "New file — OAuth feature"}
  ],
  "remedy": [
    "Commit session refactor first (behaviour-preserving).",
    "Commit OAuth file second, behind oauth_v1 flag."
  ],
  "status": "standing"
}
```

`status` ∈ `standing | escalated`. **On lift, the navigator deletes `veto.json` entirely** (the lift event is appended to `dissent-log.jsonl`). **File presence is the atomic source of truth for "standing veto right now."** Absence = cleared. This makes the hook check a simple `fs.existsSync` followed by hash-match on `blocked_action_ref`.

On `escalated`, the file stays in place with `status: escalated` until a human writes an override entry to `overrides.jsonl` and removes the file (or the navigator lifts it).

When the PreToolUse hook refuses on standing veto, it returns:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "TBD veto v-2026-05-19-001 standing — XP/small-batches: Commit bundles refactor with new feature. Remedy: split into two commits."
  }
}
```

The reason field is built from `veto.json.principle`, `veto.json.principle_source`, `veto.json.reason`, and first item of `veto.json.remedy`.

### `navigator-questions.jsonl` (append-only)

```jsonl
{"id":"q-001","asked_at":"2026-05-19T15:33:00Z","cites":[{"file":"src/auth/oauth.ts","lines":"23-29"}],"question":"What does validate_token return on expired tokens?","veto_consideration":"pa-2026-05-19-014","per_veto_question_count":1,"session_question_count":1}
```

Hook applies D-026 budgets (3 per-veto / 12 per-session) by reading the counts before accepting a new question.

### `pilot-responses.jsonl` (append-only)

```jsonl
{"in_response_to":"q-001","responded_at":"2026-05-19T15:33:42Z","answer":"Returns null. Token validation is in src/auth/jwt.ts.","scope_check":"narrow"}
```

`scope_check` is pilot's self-tag — `narrow` means "I answered only what was asked." Retro skill audits for overly broad responses.

---

## 5. Audit logs (gitignored by default; committable for team retros)

### `action-trace.jsonl` (append-only)

```jsonl
{"id":"act-001","at":"2026-05-19T15:35:00Z","tool":"Bash","command_redacted":"git commit -m '...'","pending_action_ref":"pa-2026-05-19-014","veto_at_action_time":null,"outcome":"success"}
```

Every state-changing pilot action lands here. Commands redacted if they may contain secrets (heuristic: anything matching `--password=`, `Authorization:`, etc., is replaced with `[redacted]`).

### `dissent-log.jsonl` (append-only)

```jsonl
{"event":"veto_raised","veto_id":"v-001","at":"2026-05-19T15:34:30Z","principle":"small-batches","blocked_action_ref":"pa-014"}
{"event":"veto_sustained","veto_id":"v-001","at":"2026-05-19T15:35:10Z","pilot_rebuttal":"Argued the refactor is necessary precondition."}
{"event":"veto_lifted","veto_id":"v-001","at":"2026-05-19T15:36:00Z","lifted_by":"navigator","reason":"Pilot split into two commits."}
{"event":"veto_escalated","veto_id":"v-002","at":"2026-05-19T15:50:00Z","to":"human","reason":"Deadlock after 2 dispute rounds."}
```

Event types: `veto_raised | veto_sustained | veto_lifted | veto_escalated | human_resolved`.

### `overrides.jsonl` (append-only)

```jsonl
{"id":"o-001","at":"2026-05-19T15:40:00Z","veto_overridden_ref":"v-001","reason_given":"Hotfix for prod; flag wrapping unsafe under current load","authorised_by":"human","session_id":"s-001","action_permitted_ref":"pa-014"}
```

Every override audited; retro reads these.

---

## 6. Role-swap (currently disabled in v0; reserved schema)

Per D-035, mechanical role-swap is deferred. Schema reserved for paired-mode usage and future autonomous-mode revision.

### `handoff-<n>.json`

```json
{
  "version": 1,
  "swap_id": "h-001",
  "swap_at": "2026-05-19T16:30:00Z",
  "outgoing": {"agent": "claude-sonnet-4-6", "role": "pilot"},
  "incoming": {"agent": "claude-opus-4-7", "role": "pilot"},
  "current_intent_ref": "intent-001",
  "test_state": "green",
  "last_commit_sha": "a3f8c12",
  "open_questions": [],
  "decisions_in_my_turn": ["Used oauth4 lib over oauth5 — fewer transitive deps"],
  "uncertainties": ["Token refresh policy"],
  "principles_under_pressure": ["batch-size"],
  "standing_vetoes": []
}
```

---

## 7. Status surface

### `STATUS.md`

Regenerated by `tbd-session-init` hook on each session start and after key state changes (vetoes, intent declarations, commits). Markdown so any agent reading any file in the workspace gets context.

```markdown
# TBD Status — Session s-2026-05-19-001

**Mode:** paired  |  **Effort tier:** standard
**Current intent:** feature — Add OAuth login behind oauth_v1 flag (intent-001)

## Divergence from trunk
- Named branch: feature/oauth-v1 — 3h 12m since merge-base
- Working tree: 18m (oldest unstaged change)
- Stash: empty
- **Current divergence age: 3h 12m of 24h cap (13% of budget)**
- Commits on branch: 4 of 10 cap
- Files changed: 6 of 50 cap

## Trunk
- Last green CI: 12 minutes ago ✓
- Stop-the-line: clear

## Session
- Vetoes raised: 1 (lifted) | Overrides: 0
- Questions asked: 2 of 12 session budget

## Principles under attention
- **Small batches** — current diff is 187 lines (cap 400)
```

---

## 8. State machine (the veto lifecycle)

```
[no veto]
   |
   |  pilot proposes action → writes pending-action.json
   v
[pending review]
   |
   |  pilot invokes navigator subagent (Agent tool)
   v
[under review]  ── navigator asks question ──→ [Q&A loop, bounded by D-026 budgets]
   |
   ├── navigator writes veto.json status=standing → [standing]
   └── navigator writes nothing (or status=lifted) → [cleared]

[standing]
   |
   ├── pilot revises approach → back to [pending review] (new pending-action.json)
   ├── pilot writes rebuttal in dissent-log → [disputed]
   └── human writes override entry → [overridden]

[disputed]
   |
   ├── navigator holds → [standing] (round counter ++)
   ├── navigator lifts → [cleared]
   └── round counter reaches 2 → [escalated]

[escalated]
   |
   └── halt pending human resolution → [cleared] or [sustained-final]

[cleared]
   |
   └── pilot performs action → action-trace.jsonl entry → [no veto]
```

---

## 9. Validation

Every schema has a JSON Schema definition shipped at `principles/schemas/<name>.schema.json` in the plugin. The `tbd` CLI validates files on read; malformed files trigger a hard-block with explicit reason ("malformed `.tbd/veto.json` — schema validation failed at `evidence[0].lines`"). Schema versions are bumped explicitly; migrations live in `bin/tbd.js`.

---

## 10. Lifecycle and rotation

- **Per-session files** cleared at session end: `pending-action.json`, `veto.json`, `navigator-questions.jsonl`, `pilot-responses.jsonl`. Moved to `.tbd/archive/<session-id>/`.
- **Append-only audit logs** (`action-trace.jsonl`, `dissent-log.jsonl`, `overrides.jsonl`) rotate when exceeding 10 MB. Compressed `.tbd/archive/<session-id>/<name>.jsonl.gz`.
- **STATUS.md** regenerated; never archived.
- **Handoff artifacts** preserved with session archive.

---

## 11. .gitignore template (shipped by `/tbd:init`)

```
# .tbd state — gitignored by default
.tbd/current-intent.json
.tbd/session-state.json
.tbd/pending-action.json
.tbd/veto.json
.tbd/navigator-questions.jsonl
.tbd/pilot-responses.jsonl
.tbd/action-trace.jsonl
.tbd/dissent-log.jsonl
.tbd/overrides.jsonl
.tbd/handoff-*.json
.tbd/STATUS.md
.tbd/archive/

# Keep committed:
# - .tbd/config.yaml
# - .tbd/principles-additions.md
# - .tbd/invariants.md
# - .tbd/entry-points.yaml
# - .tbd/flags.yaml
```

Teams that want to commit dissent/override logs for cross-session retros remove those lines.

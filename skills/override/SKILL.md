---
description: Human one-shot override of the next blocked action. Requires a reason. Logged to .tbd/overrides.jsonl for audit. Deletes the standing veto so the next state-changing action proceeds.
---

# /oh-my-tbd:override

Use this skill when the user invokes `/oh-my-tbd:override <reason>` and there is a standing navigator veto blocking the pilot.

## Arguments

```
/oh-my-tbd:override <reason...>
```

- `<reason>` — free-text justification, required. The reason is permanent in the audit log and feeds retro analysis. Do not synthesise a reason — if the user invoked with no text, ask them for one.

## What you do

### 1. Verify there is something to override

Read `.tbd/veto.json`:

- If absent → refuse: "No standing veto. Nothing to override." Stop.
- If `status: "escalated"` → this is the override path for an escalated veto; proceed to step 2.
- If `status: "standing"` → proceed to step 2.

### 2. Check the mode

Read `.tbd/session-state.json`:

- If `mode: "autonomous"` and the invoker is the pilot agent (not the human): **refuse**. Per `config.yaml.override.human_only_in_autonomous` (default `true`), only the human can override in autonomous mode. Tell the pilot: "Autonomous override blocked. Escalate to the human; only they can override in this mode."
- If `mode: "paired"` or the invoker is the human: proceed.

Walking-skeleton note: mode detection isn't built yet. Treat invocations as human-driven by default and proceed. The autonomous-mode block will land when mode detection is wired (see `DESIGN-LOG.md` Q-007).

### 3. Read the veto being overridden

Capture from `.tbd/veto.json`:

- `id` → `veto_overridden_ref`
- `blocked_action_ref` → `action_permitted_ref`

Read `.tbd/session-state.json.session_id` → `session_id`.

### 4. Compose the override entry

One JSONL line, schema per `SCHEMAS.md §5`:

```json
{
  "id": "o-<YYYY-MM-DD>-<NNN>",
  "at": "<iso-now>",
  "veto_overridden_ref": "<veto-id>",
  "reason_given": "<user-supplied reason, verbatim>",
  "authorised_by": "human",
  "session_id": "<session-id>",
  "action_permitted_ref": "<pa-id>"
}
```

Counter `NNN` is per-day. List existing `.tbd/overrides.jsonl` entries with today's prefix to pick the next number.

### 5. Append to `.tbd/overrides.jsonl`

Use `Edit` (or `Write` if file does not exist). This itself is a state-changing tool call; follow the standard pilot loop — write `.tbd/pending-action.json`, invoke navigator, read veto. The navigator's job here is to verify the override entry is well-formed; it should not veto a properly-formed override (the override IS the disagreement).

If the navigator vetoes the override write itself, that is a navigator bug or a malformed entry — surface it and stop.

### 6. Append a dissent-log event

Also append to `.tbd/dissent-log.jsonl`:

```json
{"event":"human_resolved","veto_id":"<veto-id>","at":"<iso-now>","resolution":"overridden","override_ref":"<override-id>","reason":"<reason>"}
```

This makes the override visible in `/oh-my-tbd:retro` analysis.

### 7. Delete `.tbd/veto.json`

Use `Bash` with `rm .tbd/veto.json`. The veto-check hook will see the absent veto on the next state-changing call and allow it through (subject to the standard pending-action check).

This is **one-shot** per `config.yaml.override.expires_after_action: true`. The next action the pilot takes is permitted; the action after that goes through the normal review loop. If the pilot needs to override again, the user re-runs `/oh-my-tbd:override` with a fresh reason.

### 8. Confirm to the user

One line:

```
Override <override-id> recorded. Veto <veto-id> cleared. Reason: "<reason>". Next state-changing action permitted; subsequent actions resume normal review.
```

## What you do NOT do

- Do not delete `.tbd/veto.json` before writing to `.tbd/overrides.jsonl`. The audit entry must land first; the bypass is the consequence.
- Do not modify the veto file's contents (e.g., flip `status` to `lifted`). Override and lift are different events — the navigator lifts, the human overrides.
- Do not invent a reason for the user. The reason is the substance of the audit trail.
- Do not refuse based on the navigator's principle alone. The user has the authority to override any single veto; the discipline accumulates the override count and surfaces patterns in retro (per LEAN/`amplify-learning`).
- Do not auto-suppress future vetoes of the same principle. Each veto is reviewed independently.

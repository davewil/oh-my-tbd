---
description: Declare the type and description of the current work unit. Writes .tbd/current-intent.json so the navigator knows what rubric branch to apply. Required before any state-changing tool call.
---

# /oh-my-tbd:start

Use this skill when the user invokes `/oh-my-tbd:start <type> <description>` or when no `.tbd/current-intent.json` exists and the pilot is about to begin a work unit.

## Arguments

```
/oh-my-tbd:start <type> <description...>
```

- `<type>` — exactly one of: `feature`, `fix`, `refactor`, `chore`, `docs`, `test`
- `<description>` — free-text summary of the work unit, one sentence

If the user invoked the command with no arguments, ask them for both. Do not guess the type.

## What you do

### 1. Validate the type

If `<type>` is not in `{feature, fix, refactor, chore, docs, test}`, refuse and explain the allowed set. Stop.

### 2. Ensure `.tbd/` exists

```bash
mkdir -p .tbd
```

This is a read-only-ish setup step; the veto-check hook treats `mkdir` as a state-changing Bash call, so this step itself requires a pending-action declaration. To avoid the chicken-and-egg, perform this `mkdir` only if `.tbd/` is missing **and** you are operating as the pilot under user invocation of this skill (not under autonomous pilot loop). If the hook refuses, instruct the user to run `mkdir -p .tbd` themselves once.

### 3. Check for an existing current intent

If `.tbd/current-intent.json` already exists:

- Read it.
- If the existing intent is for the **same work unit** the user is now restating (matching type and description close enough), proceed to overwrite — this is a no-op restatement.
- Otherwise: stop. Tell the user "An intent is already declared (`<existing.type>` — `<existing.description>`). Close it out by completing the work or removing `.tbd/current-intent.json` before declaring a new one." Do not silently overwrite — overwriting drops navigator context mid-flight.

### 4. For `type: feature` — handle the flag

`feature` work requires a flag unless non-interaction is provable (D-004 + D-027). Parse the description for a phrase like `behind <flag_name>` or `flag <flag_name>`. If found, capture it. If not found, ask the user: "Which flag name will gate this feature? (Reply `none` if claiming non-interaction; the navigator will hold you to it.)" Capture the answer as `flag_name`, or `null` if the user replied `none`.

### 5. Write `.tbd/current-intent.json`

Schema per `SCHEMAS.md §3`. Use the `Write` tool. Required pending-action setup:

a. Write `.tbd/pending-action.json` first with `{"version":1, "id":"pa-<today>-<NNN>", "proposed_at":"<iso>", "tool":"Write", "intent_str":"write .tbd/current-intent.json", "diff_summary":{"files_changed":1,"lines_added":N,"lines_removed":0,"files":[".tbd/current-intent.json"]}, "intent_ref":"<intent-id>"}`.

b. Invoke the navigator subagent via the Agent tool with `subagent_type: "navigator"` and a brief description. The navigator may clear the action (writing to `.tbd/` is in-scope for normal pilot work).

c. After navigator returns, check `.tbd/veto.json`. If clear, proceed.

d. Write `.tbd/current-intent.json` with:

```json
{
  "version": 1,
  "id": "intent-<YYYY-MM-DD>-<NNN>",
  "declared_at": "<iso-now>",
  "declared_by": "human",
  "type": "<type>",
  "description": "<description>",
  "flag_name": "<flag_name-or-null>",
  "expected_scope": {
    "files_touched_estimate": null,
    "is_pure_refactor": <true-if-type==refactor-else-false>,
    "touches_migrations": false,
    "touches_entry_points": []
  }
}
```

Counter `NNN` is per-day. To find the next number, list any `.tbd/archive/<session>/intent-<today>-*.json` plus the current value; increment. For the walking skeleton, default to `001` if no prior intent exists today.

### 6. Confirm to the user

One line:

```
Intent declared: <type> — <description> (intent-<id>, flag: <flag_name-or-none>). Navigator scoped to this work unit.
```

Then return. The pilot's normal loop takes over from here.

## What you do NOT do

- Do not start the work unit. The user (or the pilot's autonomous loop) decides what comes next.
- Do not modify `.tbd/veto.json` — only the navigator clears its own vetoes.
- Do not skip the navigator-review step before writing `.tbd/current-intent.json`. The discipline applies to the discipline itself.
- Do not write a `feature`-type intent without an explicit flag decision (registered flag or explicit `none` from the user). Ambiguity is a veto.

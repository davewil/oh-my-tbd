---
description: One-screen dashboard of TBD discipline state. Reads .tbd/ + git state, surfaces drift visibly with <unknown>/<drifted> sentinels, and ends with a Next: line picking the right action from the 9-row state-machine. Layer-1 walking-skeleton.
---

# /oh-my-tbd:status

Use this skill when the user invokes `/oh-my-tbd:status` or when the pilot wants a single-screen orientation of TBD state before deciding what to do next.

This is the **Layer-1 walking-skeleton** for the suite's status surface. Its job is to be *honest about what it doesn't know* — when a datum is missing or drifted, output `<unknown>` or `<drifted>` rather than failing or fabricating. Visible gaps are how subsequent intents (intent-003+) prioritise substrate work.

Gated by the `tbd_status_skill` flag in `.tbd/flags.yaml`. The Layer-1 convention is `flag_system: none` — presence of this SKILL.md file IS the call site.

## What you do

### 1. Gather state

Read the following. For each missing/unparseable input, record `<unknown>` (datum genuinely absent) or `<drifted>` (datum present but stale relative to another source). Do not fabricate.

**From `.tbd/`:**
- `current-intent.json` — `id`, `type`, `description`, `flag_name`, `status` (open / completed). Absent → no current intent.
- `pending-action.json` — `id`, `tool`, `intent_str`, `intent_ref`. Absent → no pending action.
- `veto.json` — `id`, `principle`, `principle_source`, `reason`, `status` (standing / escalated). Absent → no standing veto.
- `dissent-log.jsonl` — count total events; count `veto_raised` and `veto_lifted` since session start.
- `session-state.json` — `session_id`, `mode`, `counts.*`. If `counts.vetoes_raised` is below the dissent-log count, flag the counter as `<drifted>`.
- `archive/` — count archived pa-cycles since session start (subdir count under the current session id).

**From git:**
- `git rev-parse --short HEAD` — current SHA
- `git status --short` — working-tree state (clean / dirty + uncommitted file count)
- `git log --oneline @{u}..HEAD` — commits ahead of upstream (0 if in sync; `<unknown>` if no upstream configured)
- `git log --oneline HEAD..@{u}` — commits behind upstream
- Divergence age: take max of (oldest uncommitted-change mtime, branch age since merge-base, oldest stash age). If the per-axis tooling isn't wired yet, output `<unknown>` for each axis the skill cannot compute — do NOT silently pick one.

### 2. Format the dashboard

A one-screen output. Use this template (collapse blocks that are empty/absent):

```
TBD STATUS — <session_id-or-<unknown>>

Intent       : <id> — <type>: <description>  [<status>]
                flag: <flag_name-or-none>
Pending pa   : <id> — <tool>: <intent_str>   (or "none")
Veto         : <id> — <principle_source>/<principle>: <reason>  [<status>]   (or "none")

Working tree : <clean | dirty (N files)>
HEAD         : <short-sha>
Divergence   : branch-age=<...> wip-age=<...> stash-age=<...> ahead=<N> behind=<N>
                (each axis is <unknown> if the helper isn't wired yet)

Counters     : vetoes_raised=<N | <drifted>>  vetoes_lifted=<N | <drifted>>
                archived_pas=<N>  dissent_events_since_session_start=<N>

**Next:** <one-line suggestion per the state-machine below>
```

### 3. Apply the state-machine (first match wins, top-to-bottom)

Evaluate in this order; emit the first matching `Next:` suggestion. Stop on first match.

| # | Detected state | Next: suggestion |
|---|---|---|
| 1 | `.tbd/` directory does not exist | `/oh-my-tbd:init` (when implemented) — bootstrap project |
| 2 | `.tbd/veto.json` exists with `status: standing` | Address the standing veto: revise the pa, or file dissent in `.tbd/dissent-log.jsonl` |
| 3 | `.tbd/pending-action.json` exists AND no standing veto | Invoke the navigator subagent for review |
| 4 | No current-intent (absent or `status: completed`) AND working tree dirty | `/oh-my-tbd:start <type> "<description>"`, then declare pa for the changes |
| 5 | No current-intent AND working tree clean AND local ahead of origin | `git push origin main` |
| 6 | Current-intent open AND working tree clean AND no pending-action | Declare next pa, or close intent |
| 7 | Current-intent open AND working tree dirty AND no pending-action | Declare pa for the changes |
| 8 | Everything clean (intent closed, tree clean, in sync with origin) | `/oh-my-tbd:start` next work-unit (or stop) |
| 9 | Unknown state (none of above match) | `Unknown state — manual investigation needed` + raw state dump from step 1 |

### 4. Sentinel rule

When any datum in the dashboard is `<unknown>` or `<drifted>`, that visibility IS the value. Do not paper over gaps. Do not synthesise plausible values. Each visible sentinel is potential input to intent-003+ (subsequent work-units that drop down to substrate to fix the gap).

If row 9 is matched, dump the full raw state collected in step 1 below the `Next:` line so the human can see exactly which combination escaped the table.

### 5. Output the result

Print the formatted dashboard + Next: line to the conversation. Do not write to disk. Status is read-only.

## What you do NOT do

- Do not write to `.tbd/`. Status is read-only — no pa needed.
- Do not fabricate values for missing data. `<unknown>` and `<drifted>` are first-class outputs.
- Do not skip the state-machine evaluation. Always end with a `Next:` line, even if only row 9 matches.
- Do not invoke other tools or skills as part of status. If `Next:` suggests an action, surface it but do not execute it — the pilot/human decides.
- Do not collapse two state-machine rows into one — first match wins, by design. Reordering breaks the contract.

## Walking-skeleton scope

This is Layer 1. Known limitations, surfaced visibly via `<unknown>`/`<drifted>` rather than papered over:

- Divergence-age helper does not exist yet → axes show `<unknown>` (likely intent-003 bite).
- `session-state.json` counter maintenance is not wired → likely shows `<drifted>` when counts disagree with `dissent-log.jsonl` (likely intent-003+ bite).
- No `flag_system` provider integration — Layer 1 uses presence-of-SKILL.md as the gate.
- The "Next:" suggestions reference future skills (`/oh-my-tbd:init`) that don't exist yet — that's intentional; new skills plug in by adding rows.

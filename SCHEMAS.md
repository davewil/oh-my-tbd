# Schemas

The post-reset data contract. Two files in `.tbd/`. Neither is gated by JSON Schema validation — the pilot reads them, the human reads them, and that's the audience.

For what *used to* live here (the pilot↔navigator filesystem message bus — pending-action, veto, dissent-log, session-state, navigator-questions, pilot-responses, action-trace, overrides, handoff), see [DESIGN-LOG.md](./DESIGN-LOG.md) — those schemas were retired by the session-9 architectural reset and the corresponding files were deleted in slices 6–9.

---

## `.tbd/current-intent.json` — the sticky note

Gitignored (see [.gitignore](./.gitignore)). Session-local. One file at a time; the next intent overwrites the previous.

**Suggested shape** (informal — this is a conversational note, not a contract):

```json
{
  "type": "feature",
  "description": "what you're working on, in one sentence"
}
```

- `type` ∈ `feature | fix | refactor | chore | docs | test`. The type is a hint, not a verdict — see [agents/pilot.md](./agents/pilot.md) §Intent for what each one implies. If the work changes shape, re-declare.
- `description` is plain prose. Long enough to remind you what you're doing on resume; short enough to fit on a sticky note.

Additional fields (an id, timestamps, scope hints, prior-intent references) are fine if useful, but nothing reads them mechanically. The pilot reads the file on session start to orient; that's the only consumer.

The file is gitignored because it's session-local state, not project artefact. If you want a durable record of intent across sessions, the commit messages and `git log` are where that lives.

---

## `.tbd/flags.yaml` — the flag registry

Committed (not gitignored). Tracks every feature flag introduced by the project's own development.

```yaml
version: 1
flag_system: none              # walking-skeleton: presence of skills/<name>/SKILL.md acts as the Layer-1 gate

flags:
  <flag_name>:
    created: 2026-05-22
    created_for_intent: intent-2026-05-21-010
    status: active             # active | retiring | removed
    targeting_summary: "0% rollout — gated by presence of skills/<name>/SKILL.md"
    call_sites:
      - file: skills/<name>/SKILL.md
        line: 1
        function: "/oh-my-tbd:<name>"
    owner: oh-my-tbd
    # retire_by: optional ISO date
```

`flag_system` is `none` until a real provider lands; for now the **Layer-1 walking-skeleton convention** is in force: the presence of `skills/<name>/SKILL.md` *is* the flag's on-state. Delete the skill file → the flag is effectively off. This keeps the plugin self-contained until a multi-provider story is needed.

When a real provider lands, `flag_system` becomes one of `growthbook | launchdarkly | unleash | configcat | custom` and the per-flag block gains a provider-specific config reference. That's a future-session decision; YAGNI applies.

---

## What's not here

- No `pending-action.json`, no `veto.json`, no `dissent-log.jsonl`. The discipline lives in conversation, not in filesystem state.
- No `STATUS.md`. `git status` shows what matters.
- No JSON Schema files in `principles/schemas/`. The two files above are read by humans and the pilot agent; no machine validation.
- No `archive/`. The git history is the archive.

# Components

What's actually on disk in the oh-my-tbd plugin after the session-9 architectural reset and the session-10 thinning.

The plugin is small: a system prompt, a fat-finger guard hook, and a stub. Everything else was removed when the gatekeeper architecture (navigator subagent + pa-coordination + dissent log + ~9 hooks + ~12 skills) was retired in favour of conversational discipline backed by a narrow safety hook.

---

## Inventory

| Path | What it is |
|---|---|
| `agents/pilot.md` | The system prompt. Frames work as XP under TBD discipline: small commits, test-first on features/fixes, frequent integration, refactors as first-class commits, intent as a one-line sticky note. Activated as the default agent via `settings.json`. |
| `settings.json` | `{"agent": "pilot"}` — makes the pilot persona the main thread when the plugin loads. |
| `skills/pair/SKILL.md` | Stub for `/oh-my-tbd:pair`. Acknowledges the pairing posture; the sidecar mechanism is deferred (session-9 decision `(b2)`). For now the human voices the four pair objections in chat. |
| `hooks/hooks.json` | One PreToolUse matcher on `Bash`. Invokes `bin/tbd.js hook safety-check`. |
| `bin/tbd.js` | The CLI. ~245 lines. Subcommands: `version`, `hook safety-check`. The safety-check refuses three operations on trunk: `git push --force` (incl. `-f` / `--force-with-lease`), `git reset --hard`, `git branch -D <trunk>` (incl. `--delete --force <trunk>`). Anything else returns `allow`. |
| `test/hook/test-s3-narrow-refuse-on-trunk.sh` | The regression test. 11 cases pinning the safety-check contract: 6 refusals on trunk, 5 permits (non-trunk branches, non-chainsaw commands, soft resets). |
| `principles/principles.md` | XP / TBD / LEAN reference reading. No longer rubric-as-code (the rubric machinery was deleted); kept as a reading surface for the pilot or any human curious about the underlying practice. |
| `.tbd/flags.yaml` | Flag registry. Currently one entry: `tbd_pair_skill` (the walking-skeleton convention — Layer 1 gate is presence of `skills/<name>/SKILL.md`). |
| `.tbd/current-intent.json` | Session-local sticky note. Gitignored. See [SCHEMAS.md](./SCHEMAS.md) for the shape. |

---

## What's *not* here (deleted in slices 6–9)

For readers coming from an earlier draft of this doc:

- No navigator subagent. No `agents/navigator.md`.
- No filesystem message bus. No `pending-action.json`, no `veto.json`, no `navigator-questions.jsonl`, no `pilot-responses.jsonl`, no `dissent-log.jsonl`, no `action-trace.jsonl`, no `overrides.jsonl`, no `session-state.json`, no `STATUS.md`, no `archive/`.
- No `/tbd:start`, `/tbd:status`, `/tbd:override`, `/tbd:retro`, `/tbd:swap`, `/tbd:declare-intent`, `/tbd:navigator-review`, `/tbd:doctor`, `/tbd:check`, `/tbd:flag`, `/tbd:init`, `/tbd:audit` — none of these were built, and the plugin no longer claims they will be.
- No language adapters, no adversarial corpus, no CI templates.

Audit lives in `git log` + `git reflog` + the conversation transcript. There is no separate ledger.

---

## Cross-references

- [SCHEMAS.md](./SCHEMAS.md) — the (small) data contract for `.tbd/current-intent.json` and `.tbd/flags.yaml`.
- [VALIDATION.md](./VALIDATION.md) — what counts as "working" post-reset: one hook test green + human-judged dogfood.
- [DESIGN-LOG.md](./DESIGN-LOG.md) — pinned decisions, including the session-9 reset and the eight structural decisions that produced this shape.
- [agents/pilot.md](./agents/pilot.md) — the prompt itself. The most important file in the plugin.

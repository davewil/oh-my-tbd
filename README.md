# oh-my-tbd

A Claude Code plugin that brings Trunk-Based Development discipline and rigour to agentic development.

> **Status:** post-reset (session-10, 2026-05-22). The plugin loads via `claude --plugin-dir .` and applies two things: the pilot system prompt (activated as the default agent) and a narrow PreToolUse hook that refuses three irrecoverable git operations on trunk. The pair voice is a deferred sidecar — for now the human plays the pair.

## What it does (post-reset shape)

- **A pilot agent persona** (`agents/pilot.md`) that frames work as XP under TBD discipline. Small commits, test-first on features and fixes, frequent integration to trunk, refactors as first-class commits, intent declaration as a one-line sticky note. The discipline lives in the model's behaviour under the prompt, not in heavyweight tooling.
- **A narrow safety hook** that mechanically refuses three irrecoverable git operations on trunk: `git push --force`, `git reset --hard`, `git branch -D <trunk>`. Everything else is conversation, not refusal.
- **A pair stub** (`/oh-my-tbd:pair`) that surfaces the pairing posture. The full sidecar mechanism — a shared-context advisory voice in the main thread — is deferred to a future session; for now the human acts as the pair.

## Design docs

Read in this order on first encounter:

1. **[COMPONENTS.md](./COMPONENTS.md)** — what gets built (bird's-eye).
2. **[SCHEMAS.md](./SCHEMAS.md)** — the `.tbd/` data contract (data plane).
3. **[DESIGN-LOG.md](./DESIGN-LOG.md)** — pinned decisions + open questions (rationale audit).
4. **[VALIDATION.md](./VALIDATION.md)** — what "v0 done" means (the bar).

## Bootstrap and self-dogfood (per D-041)

This project uses its own discipline from the moment a minimum loop is loadable. Bootstrap option (c) was chosen: load the plugin in dev mode (`claude --plugin-dir .`) from commit #1, then incrementally wire in the real checks. Each new check applies to oh-my-tbd's own development as soon as it ships.

The plugin's safety hook is live from the moment it loads. See [NEXT-SESSION.md](./NEXT-SESSION.md) for the current state and build order.

## Develop

```bash
claude --plugin-dir .
```

The plugin loads namespaced as `oh-my-tbd`. The `pilot` agent appears in `/agents`. Skills appear as `/oh-my-tbd:pair` (stub — placeholder for the deferred sidecar mechanism).

Verify the bootstrap:

```bash
node ./bin/tbd.js version
```

## Status

This is pre-release software in active design and bootstrap. Decisions are tracked in `DESIGN-LOG.md`; supersession is explicit. Open questions are tracked alongside. There are no quality guarantees yet.

## License

TBD.

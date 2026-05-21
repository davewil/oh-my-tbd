# oh-my-tbd

A Claude Code plugin that brings Trunk-Based Development discipline and rigour to agentic development.

> **Status:** bootstrap (commit #1). The plugin loads via `claude --plugin-dir .` but applies no discipline yet — only the scaffolding is in place. The first real checks land in the next milestone.

## What it does (target state)

- **Paired mode** (interactive Claude Code session): coaches and surfaces TBD / XP / LEAN principle violations in real time. The human-and-pilot session is itself the pair.
- **Autonomous mode** (background, headless): a pilot + navigator agent pair. The navigator has mechanical veto authority via `.tbd/veto.json` and is engineered to be context-isolated from the task spec to preserve genuine critique.
- **Hard blocks** on:
  - Divergence cap exceeded (named branch, uncommitted WIP, or stash — whichever is oldest)
  - Batch size exceeded
  - Non-interaction criterion unmet for a feature commit without a registered flag
  - Standing navigator veto

## Design docs

Read in this order on first encounter:

1. **[COMPONENTS.md](./COMPONENTS.md)** — what gets built (bird's-eye).
2. **[SCHEMAS.md](./SCHEMAS.md)** — the `.tbd/` data contract (data plane).
3. **[DESIGN-LOG.md](./DESIGN-LOG.md)** — pinned decisions + open questions (rationale audit).
4. **[VALIDATION.md](./VALIDATION.md)** — what "v0 done" means (the bar).

## Bootstrap and self-dogfood (per D-041)

This project uses its own discipline from the moment a minimum loop is loadable. Bootstrap option (c) was chosen: load the plugin in dev mode (`claude --plugin-dir .`) from commit #1, then incrementally wire in the real checks. Each new check applies to oh-my-tbd's own development as soon as it ships.

The first few commits before the minimum loop is real are exempt; this exemption ends as soon as the veto-check hook is functional. See [NEXT-SESSION.md](./NEXT-SESSION.md) for the build order.

## Develop

```bash
claude --plugin-dir .
```

The plugin loads namespaced as `oh-my-tbd`. Skills appear as `/oh-my-tbd:start`. Agents appear in `/agents` as `pilot` and `navigator`.

Verify the bootstrap:

```bash
node ./bin/tbd.js version
```

## Status

This is pre-release software in active design and bootstrap. Decisions are tracked in `DESIGN-LOG.md`; supersession is explicit. Open questions are tracked alongside. There are no quality guarantees yet.

## License

TBD.

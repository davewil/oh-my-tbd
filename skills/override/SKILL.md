---
description: One-shot human override of the next blocked action. Requires a reason; logged to overrides.jsonl for audit.
---

# /oh-my-tbd:override (bootstrap stub)

> **Status:** stub. Full skill behaviour lands in the next session. See `NEXT-SESSION.md` priority 5.

Usage:

```
/oh-my-tbd:override <reason>
```

## Target behaviour

1. Refuse if no standing veto exists (`.tbd/veto.json` absent) — nothing to override.
2. Refuse in autonomous mode unless the navigator has concurred (D-035 reserves true override authority to human-in-loop).
3. Append an entry to `.tbd/overrides.jsonl` per SCHEMAS.md §5 with the reason, the veto reference, the session id.
4. Delete `.tbd/veto.json` so the next state-changing action proceeds (one-shot).
5. Confirm to the human, citing the audit entry id.

Until then, this skill is a no-op placeholder so the plugin loads cleanly.

---
description: Declare the type and goal of the current work unit (feature/fix/refactor/chore/docs/test). Records intent for the navigator to read.
---

# /oh-my-tbd:start (bootstrap stub)

> **Status:** stub. Full skill behaviour lands in the next session. See `NEXT-SESSION.md` priority 5.

Usage:

```
/oh-my-tbd:start <type> <description>
```

Where `<type>` ∈ `feature | fix | refactor | chore | docs | test`.

## Target behaviour

1. Validate type against the allowed set.
2. Write `.tbd/current-intent.json` per SCHEMAS.md §3 with `declared_by: human`, the type, description, and (for `feature`) the required flag name.
3. If `current-intent.json` already exists for a different intent, prompt to close out the previous unit first.
4. Surface a short confirmation: intent declared, navigator now scoped to this work unit.

Until then, this skill is a no-op placeholder so the plugin loads cleanly.

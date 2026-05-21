---
description: Surface the human as the pair voice while the sidecar mechanism is being chosen. Reminds the pilot that the four pair objections (missing test, oversized batch, divergence-age, mixed concerns) will come from the human in chat until a sidecar agent or hook-emitted prompt is wired up.
---

# /oh-my-tbd:pair

Use this skill when the user invokes `/oh-my-tbd:pair`. It is intentionally a stub: the sidecar mechanism isn't built yet, so the human acts as the pair voice in the meantime.

## What you say

Acknowledge the pairing posture in one short message. A default wording:

> "Pairing on. The human voices the four pair objections in chat: missing test, oversized batch, divergence-age, mixed concerns. The sidecar mechanism isn't built yet — for now, the human's voice is the pair's voice. Carry on; the human will speak up when something looks off."

Adapt to fit the conversation. Brevity matters; the user already knows what pairing means.

## What this skill does NOT do

- It does not toggle a flag, write a `.tbd/` file, or invoke any subagent.
- It does not change the pilot's tool surface or refuse anything.
- It is a posture announcement, not a state change.

## Future shape

The sidecar mechanism (session-9 decision `(b2)`) is currently deferred. When it lands, this skill grows into the actual wiring — either a shared-context sidecar instance, a hook-emitted per-turn prompt, or both. Until then: stub.

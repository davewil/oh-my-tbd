# Session archives

This directory holds the durable record of each working session — what was attempted, what landed, what was learned. Extracted from `NEXT-SESSION.md` at the end of session 6 (intent-016) once the inlined history began degrading agent context quality at session-start.

## Layout

- `session-N.md` — one file per session, numbered chronologically (1, 2, 3, ...).
- Each file follows a uniform shape:
  1. **Header** — date, intents covered, commit range (short SHA → short SHA + count), one-line outcome headline.
  2. **Commit chain** — the table rows that previously lived in `NEXT-SESSION.md`'s commit-table for that session.
  3. **Progress block** — the goal / outcome / lessons / substrate-observations content verbatim from when it was originally written. No paraphrase; this is archival, not editorial.

## Reading order

`NEXT-SESSION.md` carries a compact Past-sessions index with a one-line summary + link per file. Read those at session-start; follow the link into the relevant session-N.md only when you need depth on what was previously decided or attempted.

## Adding a new session

When closing a session, append a new `session-N.md` here following the shape above, and add its one-line summary + link to the Past-sessions index in `NEXT-SESSION.md`. The progress-block content should match what would otherwise have been inlined.

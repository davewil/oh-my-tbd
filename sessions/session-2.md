# Session 2 — 2026-05-20 — D-052 archive-on-failure negative-case test

**Intents:** intent-003 (test, no commit) → intent-004 (docs, this commit)
**Commits:** `c78c3f2` → `95bff0e` (2 commits)
**Outcome headline:** Priority 2 from session-1 NEXT-SESSION closed — `test-d052-archive-on-failure.sh` lands with success=false + success-absent fixtures pinning the predicate against three mutation classes; mutation-table-by-inspection lesson captured.

---

## Commit chain

| Commit | What |
|---|---|
| `c78c3f2` | D-052 archive-on-failure negative-case test (`success=false` + `success-absent` fixtures) — pins predicate at `bin/tbd.js:191` against removal, inversion, and `!==true → ===false` softening mutations |
| `95bff0e` | NEXT-SESSION.md session-2 close-out — priority 2 done, queue renumbered, three lessons captured |

## Session 2 progress (2026-05-20, single commit `c78c3f2`)

**Goal:** close priority 2 from session-1 NEXT-SESSION — D-052 archive-on-failure negative-case test.

**Outcome:** landed. One file (`test/hook/test-d052-archive-on-failure.sh`, 103 lines), two fixtures (`success=false` + `success-absent`), all four hook tests PASS, pushed to origin. Total work-unit: ~3 commits' worth of pilot/navigator cycles compressed into one ship. (Note: intent-013 in session 6 subsequently DELETED this test on fixture-honesty grounds once D-058 proved the failure path unreachable — see session-6 lessons.)

### Three lessons worth carrying forward

- **By-inspection mutation analysis caught an overclaimed docstring mid-batch.** My first version (pa-031) had a docstring claiming the test catches the `!==true → ===false` mutation. When I sat down to verify by case-by-case predicate analysis, I found `success=false` alone does NOT catch that mutation (both predicates noop for `false`). The fix was extending the test with an absent-success fixture (`tool_response: {}`) which DOES kill the mutant. **Lesson:** characterization tests need a brief manual mutation-table check before commit; "PASS against current code" is not evidence the test guards what its comment claims. The cost of the check was minutes; the cost of a silent regression hole would have been a future bug.

- **Q-035 (navigator Bash refused at `.tbd/`) manifested 3 times in this single batch.** Refused on pa-031/033/036 navigator reviews; allowed once on pa-034 vicinity. Each refusal cost ~30 sec of pilot trace-close bookkeeping (appending the navigator's veto_lifted entry to `dissent-log.jsonl` manually). The friction compounds linearly with batch count. Priority 1 (Q-035 reconciliation) is now the clear next move on cost-benefit: tightening the navigator's tool surface or extending the D-051 carve-out would eliminate this entirely.

- **The hook caught a tool-mechanic switch mid-batch.** I declared `tool: Edit` in pa-033 (incremental extension), navigator cleared, but my actual implementation grew into a structural rewrite via Write. The hook refused the Write because pa still said Edit. I had to declare pa-034 (Write) before proceeding. Crucially: the *substantive* content didn't change between pa-033 and pa-034 — only the tool mechanic. Per D-053, I proceeded without re-invoking the navigator for the tool-mechanic-only change. **Lesson:** the hook's `pa-tool === actual-tool` invariant is robust to "I'll just slip this through" reasoning even when intent feels unchanged. The invariant is mechanical and cheap; respect it.

### Substrate observations for next session

- `.tbd/archive/s-2026-05-20-001/` continues to hold session-1 pa archives; session-2 PostToolUse archives may have been written under same or distinct session_id (verify via `ls .tbd/archive/`).
- `dissent-log.jsonl` grew from 19 to 22 entries this session (three veto_lifted events for pa-031/033/036).
- `current-intent.json` ended at intent-004 (docs, this NEXT-SESSION.md update). Next session should `/oh-my-tbd:start` fresh.
- Trunk advanced one commit (`5443f48 → c78c3f2`), no divergence.

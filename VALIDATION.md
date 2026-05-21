# Validation

How we know the plugin is working post-reset.

The discipline lives in two places: a system prompt that coaches XP behaviour, and a hook that refuses three irrecoverable git operations on trunk. Each is validated differently — the hook mechanically, the prompt humanly. There is no longer a corpus-detection-rate or veto-rate-stability metric, because there is no rubric-as-code to drift against.

---

## 1. The safety hook — mechanical, one test

```bash
bash test/hook/test-s3-narrow-refuse-on-trunk.sh
```

11 cases, all GREEN on `main`:

- 6 refusals: `git push --force` / `-f` / `--force-with-lease` on trunk, `git reset --hard` on trunk, `git branch -D <trunk>` / `--delete --force <trunk>`.
- 5 permits: `git push origin main` (no force), `git reset --soft`, `git branch -D <feature>`, `ls`, `git push --force origin <feature>`.

This is the entire mechanical surface. If this test goes RED, the discipline's safety net is broken; ship a fix before anything else. If we ever want a new mechanical refusal, the bar is "would not having this cost someone irrecoverable history?" — anything else belongs in conversation.

---

## 2. The pilot prompt — judged humanly, via dogfood

`agents/pilot.md` is validated by the simple test: **when running the plugin against real work, does the pilot actually practise XP?** Small commits, test-first, frequent integration, refactors as first-class commits, intent declared, honest commit messages. Either it does or it doesn't.

Signals of a healthy session (already articulated in pilot.md §"Validating the discipline"):

- A couple of mild objections from the pair (currently the human), quick revisions, otherwise quiet flow.
- Zero objections across a session is suspicious — either perfect work or the pair is asleep. Both worth flagging.
- Constant friction means either the work unit is too big or the discipline is miscalibrated.

The audit trail for any session is `git log` + `git reflog` + the conversation transcript. That's enough to retrospect on without a separate jsonl ledger.

---

## 3. What we explicitly don't measure

Honest about the post-reset narrowing:

- **No corpus-detection rate.** No adversarial test corpus exists; the navigator that would have run against it was deleted in slice 7.
- **No veto rate, no override rate.** The pilot/navigator filesystem message bus is gone; there are no vetoes or overrides to count.
- **No principle-coverage metric.** The rubric-as-code that would have classified vetoes by principle is gone.
- **No cross-repo generalisation evidence.** The plugin runs against this one repo (`oh-my-tbd` developing itself); there is no external A/B story.
- **No long-term codebase-health study.** Out of scope for a tool this thin.

These were measured (or planned to be measured) in earlier drafts; their absence is the point. The session-9 reset traded measurement surface for design simplicity. The honest claim is: this plugin is a system prompt + a fat-finger guard, not a quality regime. It earns its keep if the prompt-and-hook combination produces visibly better behaviour than no plugin at all — which is itself a human judgement, not a metric.

---

## 4. Cross-references

- [agents/pilot.md](./agents/pilot.md) — the prompt under validation, §"Validating the discipline" for the human-judged signals.
- [COMPONENTS.md](./COMPONENTS.md) — what's on disk, including the hook and the test.
- [DESIGN-LOG.md](./DESIGN-LOG.md) — the session-9 reset decisions, including `(f1)` (drop counters/metrics) and the conscious trade between measurement surface and design simplicity.

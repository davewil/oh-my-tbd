# TBD Customisation Suite — Component Inventory (v0 sketch)

Companion to `DESIGN-LOG.md`. Sketches every component implied by the ratified policy decisions.
Not yet a build plan — that comes after walking-skeleton scoping.

- **Status:** sketch
- **Started:** 2026-05-19

---

## 1. Packaging unit

A single **Claude Code plugin** — `claude-tbd` (working name). Plugins bundle skills, hooks, agents, and assets in one installable unit; this matches D-005 (standalone, no OMC/nWave deps).

Repository layout:

```
claude-tbd/
├── plugin.json                  # Claude Code plugin manifest
├── skills/                      # slash commands
├── hooks/                       # PreToolUse / PostToolUse / SessionStart hooks
├── agents/                      # subagent definitions (navigator, pilot, etc.)
├── principles/                  # default principle / invariant content
├── adapters/                    # per-language L2 reachability adapters
├── corpus/                      # adversarial test corpus
├── templates/                   # CI workflows, .tbd/ skeletons
├── bin/                         # helper scripts called by hooks
└── README.md
```

Distribution: Claude Code plugin marketplace primarily; git-install fallback. Cross-platform (macOS/Linux/Windows) — implies portable hook implementation (see open question Q-020 below).

---

## 2. Component categories at a glance

| Category | Count (v0) | Role |
|---|---|---|
| Slash command skills | ~12 | User entry points + agent-invoked skills |
| Hooks | ~9 | Mechanical discipline backstop (the hard blocks) |
| Subagents | 5 | Navigator, pilot, doctor, flag-classifier, retro-analyst |
| Language adapters | 5 | Python, TypeScript, Go, C#, Elixir L2 reachability |
| Principle / config files | ~10 | Library defaults + user + project overrides |
| Templates | 3-5 | CI workflows, branch protection, pre-commit |
| `.tbd/` runtime state files | ~12 | The coordination substrate |

---

## 3. The `.tbd/` directory contract — most foundational

Every other component reads or writes here. Acts as the shared blackboard for pilot/navigator coordination, audit, and state.

```
.tbd/
├── config.yaml                  # project preferences (effort tier, strictness, cap values)
├── principles-additions.md      # project-level XP/TBD/LEAN extensions
├── invariants.md                # project-specific contracts
├── entry-points.yaml            # declared user-facing entry points
├── flags.yaml                   # registered feature flags
│
├── current-intent.json          # current work-unit intent (feature/fix/refactor/chore)
├── session-state.json           # mode (paired/autonomous), start time, swap count
│
├── pending-action.json          # pilot's proposed next state-changing action
├── veto.json                    # current standing veto (or absent)
├── navigator-questions.jsonl    # append-only navigator → pilot questions
├── pilot-responses.jsonl        # append-only pilot → navigator responses
│
├── action-trace.jsonl           # append-only log of every pilot state-changing action
├── dissent-log.jsonl            # append-only veto history (Kaizen surface)
├── overrides.jsonl              # append-only override audit
├── handoff-<n>.json             # role-swap handoff artifacts
│
└── STATUS.md                    # regenerated each turn; what any agent sees on read
```

User-level state lives at `~/.tbd/` with the same structure for keys that make sense globally (`config.yaml`, `principles-additions.md`). Project overrides user; user overrides library (D-022).

---

## 4. Skills (slash commands)

### User-invocable

| Skill | Purpose |
|---|---|
| `/tbd:init` | Bootstrap a project — create `.tbd/`, scan entry points, propose `entry-points.yaml`, suggest CI workflow, detect language stack, draft `invariants.md`. |
| `/tbd:doctor` | Brownfield TBD-readiness assessment. Reports gaps: branch model, CI presence, flag system, test speed, trunk health. |
| `/tbd:status` | Current alignment dashboard — divergence age (with breakdown), commits since integration, batch size, flag coverage, test state, veto count, principles snapshot. |
| `/tbd:start <type> <description>` | Declare work-unit intent. Records to `.tbd/current-intent.json`. Navigator reads this. |
| `/tbd:flag <name>` | Register a new feature flag. Updates `.tbd/flags.yaml` + scaffolds flag-check call site. |
| `/tbd:check` | Run the non-interaction criterion manually against current diff. Returns verdict + layer-by-layer trace. |
| `/tbd:override <reason>` | One-shot override of the next blocked action. Logs to `.tbd/overrides.jsonl`. |
| `/tbd:retro` | Session retrospective — reads dissent log, surfaces patterns, principle violations, override rates. |
| `/tbd:pair <mode>` | Explicitly set paired/autonomous mode. |
| `/tbd:swap` | Manual pilot↔navigator role-swap trigger. |
| `/tbd:audit [N]` | Show last N vetoes, overrides, escalations. |

### Agent-invocable (skills agents call internally)

| Skill | Purpose |
|---|---|
| `/tbd:navigator-review` | Synchronous navigator review of a pending action (D-015 Option A flow). |
| `/tbd:declare-intent` | Pilot declares intent at start of work unit; navigator reads. |

---

## 5. Hooks

### PreToolUse

| Hook | Behaviour |
|---|---|
| `tbd-veto-check` | Reads `.tbd/veto.json`. Refuses state-changing tool calls if standing veto exists. **The core discipline backstop.** |
| `tbd-divergence-cap` | Refuses state-changing actions if divergence age (branch / uncommitted-WIP / stash, whichever oldest) exceeds Q-001 cap. Per D-050. |
| `tbd-flag-check` | Refuses commits if non-interaction criterion not met and no flag registered. |
| `tbd-batch-size` | Refuses commits exceeding configured size threshold. |
| `tbd-test-state` | Refuses commits if tests not run or last run was red. |
| `tbd-navigator-tool-restriction` | When navigator is acting, restricts to read-only Bash + writes scoped to `.tbd/`. |
| `tbd-conventional-prefix` | Refuses commits without conventional prefix (configurable strictness). |

### PostToolUse

| Hook | Behaviour |
|---|---|
| `tbd-action-trace` | Append every state-changing action to `.tbd/action-trace.jsonl`. |
| `tbd-test-result-capture` | Record test outcomes for `tbd-test-state` reads. |
| `tbd-navigator-trigger` | After pilot state-changing action, trigger navigator review (Option A flow). |

### SessionStart

| Hook | Behaviour |
|---|---|
| `tbd-session-init` | Detect mode (paired/autonomous), regenerate `.tbd/STATUS.md`, check trunk health, refuse start if trunk is red. |

### UserPromptSubmit

| Hook | Behaviour |
|---|---|
| `tbd-intent-prompt` | If no current intent is declared, prompt user to declare via `/tbd:start`. |

---

## 6. Subagents

| Agent | Role | Tools | Notes |
|---|---|---|---|
| `tbd-navigator` | Critique role with veto authority | Read, Grep, Glob, read-only Bash, write to `.tbd/` only | Adversarial system prompt; effort-tier-configurable model (D-019) |
| `tbd-pilot` | Initiative role | Full standard toolset minus navigator-only paths | Balanced system prompt |
| `tbd-doctor` | Brownfield TBD-readiness audit | Read, Grep, Glob, Bash (read-only) | Invoked by `/tbd:doctor` |
| `tbd-flag-classifier` | Apply layered non-interaction criterion | Read, Grep, Glob, language-adapter Bash | Invoked by `/tbd:check`; also by `tbd-flag-check` hook |
| `tbd-retro-analyst` | Dissent-log analysis | Read | Invoked by `/tbd:retro` |

---

## 7. Language adapters

Adapter API contract:

```
detect(repo_path) -> bool                       # does this adapter apply to this repo?
reachable(diff, entry_points) -> set[symbol]    # what does the diff touch that's reachable?
dynamic_patterns(diff) -> list[Match]           # flag dynamic-wiring patterns
```

| Adapter | Strength | Backing tool |
|---|---|---|
| Python | Moderate | AST + import graph; conservative on decorators/importlib |
| TypeScript | Strong | ts-morph or tsc --listFiles |
| Go | Strong | `go list -deps -json` |
| C# | Strong | Roslyn |
| Elixir | Moderate | `mix xref graph` + macro pattern exclusion |

Languages without adapters → L2 unavailable → falls to L0+L1+pattern-exclusion per D-027.

---

## 8. Principle / config asset files

### Plugin-shipped (read-only library defaults)

| File | Content |
|---|---|
| `principles/principles.md` | TBD + XP + LEAN checklist with concrete violation patterns |
| `principles/invariants-template.md` | Starter invariants for common project shapes |
| `principles/entry-points-conventions.yaml` | Framework-default entry-point detection patterns |

### User-level (`~/.tbd/`)

| File | Content |
|---|---|
| `config.yaml` | User preferences (effort tier, default strictness) |
| `principles-additions.md` | User-level principle additions |

### Project-level (`.tbd/`)

See `.tbd/` directory contract above.

**Precedence:** library < user < project. Additions stack; overrides replace (D-022).

---

## 9. Adversarial corpus

Per D-021. Layout:

```
corpus/
├── small-batches/
│   ├── 001/{diff.patch, expected.json, description.md}
│   ├── 002/...
├── yagni/
├── non-interaction/
├── tdd-violation/
├── feature-without-flag/
├── refactor-mixed-with-feature/
├── schema-without-expand-contract/
└── ...
```

Each case: input diff, expected verdict (allow / veto-with-principle), description of what the corpus item is testing.

Used by:
- Navigator regression suite (CI for the plugin itself)
- Language adapter validation
- Quality bar before shipping prompt changes

---

## 10. Templates

| Template | Purpose |
|---|---|
| `templates/github-actions/tbd-ci.yml` | Minimal CI — lint + test + non-interaction check + dissent-log validation |
| `templates/branch-protection.json` | Branch protection ruleset (caps applied, required status checks) |
| `templates/precommit/.pre-commit-config.yaml` | Pre-commit framework hooks for local discipline backstop |

Other CI providers (GitLab, CircleCI, Azure DevOps) added later or via community contribution.

---

## 11. Visibility surfaces (Q-004 resolution sketch)

Plural surfaces, each serving a different reading moment:

| Surface | Medium | Audience |
|---|---|---|
| `/tbd:status` | Slash command output | Human, on demand |
| `.tbd/STATUS.md` | Regenerated each turn | Any agent reading any file in the workspace |
| Status line entry | Claude Code statusline (optional, opt-in) | Human, continuously |
| `/tbd:retro` | Markdown output | Human, end of session / sprint |

---

## 12. MCP server — explicitly *not* in v0

State is local files. MCP becomes interesting at team/org scale (shared dissent registry, centralised principles, cross-repo dashboards). Reserved for a future "team edition."

---

## Walking skeleton — minimum viable v0 (post-advisor cut, D-044)

Smallest set that produces a working TBD-disciplined session end-to-end. Everything below this line is enrichment built on top.

**Schemas (5):**
- `.tbd/current-intent.json`
- `.tbd/pending-action.json`
- `.tbd/veto.json`
- `.tbd/dissent-log.jsonl` (minimal — `veto_raised` and `veto_lifted` events only in v0)
- `.tbd/session-state.json`

**Hook (1):**
- `tbd-veto-check` (PreToolUse) — implements D-043 skip-detection + D-014 veto refusal + D-048 JSON deny output

**Agents (2):**
- `pilot` (activated as main thread via `settings.json` per D-049)
- `navigator` (subagent invoked by pilot via Agent tool)

**Skills (2):**
- `/tbd:start <type> <description>` — writes `current-intent.json` and walks pilot through the navigator-review flow for the first action
- `/tbd:override <reason>` — one-shot human override of next blocked action; appends to `overrides.jsonl`

**Plus:** README and install instructions.

That is the demo. The pilot invokes the navigator before each state-changing action; the navigator either clears (deletes `veto.json`) or raises (writes `veto.json` with status `standing`); the PreToolUse hook reads the file and either allows or refuses with the navigator's reason; the human can override with `/tbd:override`.

### Plugin directory layout (post primary-source verification, D-046)

```
oh-my-tbd/
├── .claude-plugin/
│   └── plugin.json              # manifest
├── settings.json                # {"agent":"pilot"} per D-049
├── agents/
│   ├── pilot.md
│   └── navigator.md
├── hooks/
│   └── hooks.json               # PreToolUse: veto-check
├── skills/
│   ├── start/
│   │   └── SKILL.md
│   └── override/
│       └── SKILL.md
├── bin/
│   └── tbd.js                   # Node CLI; invoked from hooks via exec form
├── src/                         # TypeScript sources (compiled to bin/)
├── principles/
│   ├── principles.md
│   └── schemas/                 # JSON Schemas
└── README.md
```

### Hook invocation form (D-047)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node",
            "args": ["${CLAUDE_PLUGIN_ROOT}/bin/tbd.js", "hook", "veto-check"]
          }
        ]
      }
    ]
  }
}
```

Exec form (`args` present) bypasses the shell — clean on Mac/Linux/Windows.

---

## Original walking skeleton — superseded

The earlier P1–P5 framing covered 5 of 7 phases ("build almost everything"). After advisor review, cut to the minimum loop above. Original was retained in version history; not duplicated here.

---

## Build phases (proposed, pre-decision)

| Phase | Focus |
|---|---|
| P1 — Foundation | `.tbd/` contract, principle files, `/tbd:init`, `/tbd:status` |
| P2 — Discipline backstops | Veto-check hook, batch-size hook, action-trace hook, override skill |
| P3 — Agent pair | Navigator + pilot agents, navigator-review skill, handoff protocol |
| P4 — Non-interaction criterion | Flag-check hook, flag-classifier agent, first L2 adapter |
| P5 — Audit & retros | Dissent log, retro skill, adversarial corpus + regression CI |
| P6 — Multi-language | Remaining L2 adapters (TS, Go, C#, Elixir) |
| P7 — Distribution polish | Plugin manifest, marketplace listing, docs, CI templates |

P1–P5 = walking skeleton equivalent. P6–P7 = enrichment.

---

## Open questions opened by component sketching

| ID | Question |
|---|---|
| Q-020 | Cross-platform hook implementation language — Bash / Python / Node? Affects Windows support. |
| Q-021 | Claude Code statusline coexistence — if our plugin sets statusline, how does it not conflict with user's existing one? |
| Q-022 | Plugin manifest format details — verify against current Claude Code plugin spec. |
| Q-023 | How does the navigator-review skill *actually invoke* a separate agent instance synchronously via current Claude Code primitives? (Agent tool? Spawned process? Need to validate feasibility.) |
| Q-024 | How is `entry-points.yaml` auto-detected on `/tbd:init`? Per-framework heuristics? |
| Q-025 | What's the storage format / size budget for `.tbd/action-trace.jsonl` in long-running projects? Rotation policy? |

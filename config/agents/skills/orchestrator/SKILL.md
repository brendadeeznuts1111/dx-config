---
name: orchestrator
description: "Coordinate work across Herdr panes in a project workspace. Use for handoffs between agents, reviewer escalation after finish-work, and context sync when agent status changes. Requires HERDR_ENV=1 and an enabled [herdr.orchestrator] profile."
---

# orchestrator — multi-pane coordination

Use this skill when you are the **lead agent** in a Herdr project workspace and need to close the loop across panes — not just control layout (see the `herdr` skill for that).

## Preconditions

1. `HERDR_ENV=1` — you are inside a Herdr pane.
2. Project has `[herdr]` enabled in `dx.config.toml` or `.dx/herdr.toml`.
3. Optional `[herdr.orchestrator]` block configures handoff targets (defaults: primary → first secondary).

If orchestrator is disabled or you are outside Herdr, stop and tell the user.

## Commands (PATH)

All commands take the project root (default: pane cwd).

```bash
herdr-orchestrator status .
herdr-orchestrator react .
herdr-orchestrator context-sync .
herdr-orchestrator escalate .
herdr-orchestrator react . --watch   # poll every 15s (HERDR_ORCHESTRATOR_INTERVAL)
```

Use `--json` for machine-readable output.

## When to run

| Trigger | Command | What happens |
|---------|---------|--------------|
| After workspace rebuild / layout apply | `context-sync` | Runs each `[[herdr.agentsTab.panes]].context` command and `herdr agent send`s output to that pane |
| Primary agent finished a chunk of work | `react` | On **working → idle**, syncs context (if configured) and sends handoff summary to secondary |
| `finish-work` pushed but tree still dirty | `escalate` or `react` | Opens reviewer tab and runs reviewer pane script |
| Long session with multiple agents | `react . --watch` | Background poll for state transitions |

## Coordination contract

### Pane roles (from `[herdr.agentsTab]`)

| Role | Owner | Delivers |
|------|-------|----------|
| **primary** | Lead implementer (kimi / grok) | Code changes, plans, commits via `finish-work` |
| **secondary** | Reviewer / alternate model (codex / claude) | Picks up handoff brief, challenges assumptions |
| **shell** | Human + gates | `bootstrap` commands, `bun run check:fast`, git status |
| **doctor tab** | Health | `kimi-doctor --watch` or `herdr-doctor` |
| **reviewer tab** | Post-push cleanup | `reviewer-pane.ts` when finish-work escalates |

### Handoff format

`react` captures recent output from the primary pane and sends:

```
[orchestrator handoff from kimi]
<last lines of primary scrollback>

Pick up from here or ask the primary for clarification.
```

Target is `handoffTo` (pane id scoped to this workspace — never bare agent name when multiple workspaces are open).

### Context sync

Pane `context` commands (e.g. `kimi-doctor --workspace-context --brief`) run in the **project root**, not inside the agent. Output is injected via `herdr agent send` so agents see branch, gates, and next steps after rebuild.

## Agent workflow (primary)

1. **Start of session** — ensure layout matches profile: `herdr-project reconcile .` (dry-run); user applies if drift.
2. **After major milestone** — `herdr-orchestrator react .`
3. **Before delegating to secondary** — either `react .` (automatic on idle) or `herdr agent send <secondary-pane-id> "<task>"` for explicit tasks.
4. **After finish-work with dirty tree** — confirm `herdr-orchestrator escalate .` opened reviewer tab.
5. **Stuck on blocked secondary** — `herdr agent read <pane> --source visible`; do not spam handoff.

## Config reference

```toml
[herdr.orchestrator]
enabled = true
contextOnIdle = true
handoffFrom = "kimi"
handoffTo = "codex"
reviewerTab = "reviewer"
```

## Related skills

- **herdr** — pane/tab/workspace control (`herdr pane list`, `agent send`, `wait`)
- **kimi-toolchain** — `finish-work`, `kimi-doctor`, gates

## Do not

- Run orchestrator from outside Herdr expecting pane side effects — `escalate` and `agent send` need a live server.
- Use bare agent names when multiple workspaces run the same agent label — prefer pane ids from `herdr agent list`.
- Replace `finish-work` gates — orchestrator reacts to outcomes; it does not commit or push.
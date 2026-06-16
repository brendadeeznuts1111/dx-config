# Herdr — Local DX Configuration & Agent Reference (This Machine)

Canonical upstream docs ([`website/src/content/docs/`](https://github.com/ogulcancelik/herdr/tree/master/website/src/content/docs)):

- [configuration.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/configuration.mdx)
- [session-state.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/session-state.mdx)
- [persistence-remote.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/persistence-remote.mdx)
- [agents.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/agents.mdx)

**Purpose**: Opinionated, machine-specific layer on top of upstream Herdr ([herdr.dev/docs](https://herdr.dev/docs/)).

- **Upstream** = canonical behavior, full agent matrix, integrations, session restore rules, `herdr agent` CLI, debugging tools, plugins, and marketplace.
- **This dx-config layer** (`config/dx/`, spawn stubs, `install.sh`, control skill) = how *this Mac* wires and launches its daily herd.
- **kimi-toolchain** (`src/lib/herdr-agents.ts`, `herdr-doctor`, `herdr-project`, `herdr-spawn`) = executable logic synced to `~/.kimi-code/tools/`.

This document is the single source of truth for **this machine's** agent wiring, keybindings, spawn paths, and control skill distribution. It deliberately focuses on a 6-agent subset chosen for daily work.

*Last cross-checked against upstream docs: 2026-06-16.*

---

## Post Phase 2 — Deploy chain (2026-06-16)

**Phase 2 complete:** `herdr-doctor`, `herdr-project`, `herdr-spawn`, and `herdr-spawn-*` are authored in `kimi-toolchain`, not dx-config. This repo keeps TOML/JSON, `herdr-quickref`, shell helpers, and the control skill.

**Edit rule:** change executable logic in `~/kimi-toolchain/src/{bin,lib}/herdr-*`; change wiring (keys, manifest, profiles) here.

```
kimi-toolchain (git)
  src/bin/herdr-{doctor,project,spawn}.ts
  src/lib/herdr-{agents,doctor,project-runner,project-config}.ts
        │
        │  bun run sync
        ▼
~/.kimi-code/tools/*.ts          runtime copies
~/.kimi-code/lib/herdr-agents.ts
        │
        │  bun run install-wrappers  (also invoked by dx-config install.sh)
        ▼
~/.local/bin/herdr-{doctor,project,spawn}   bash wrappers → bun run ~/.kimi-code/tools/…
~/.local/bin/herdr-spawn-{agent}            per-agent stubs (install-wrappers, from SPAWN_AGENTS)
        │
        ▼
config/dx/herdr.toml [keys.command]  →  spawn agents from panes
config/shell/herdr.sh                →  herder ~/project bootstrap
```

**Fresh machine:** clone both repos to `~/kimi-toolchain` and `~/dx-config`, then `cd ~/dx-config && ./scripts/bootstrap-machine.sh`.

**Do not recreate** `~/.config/dx/lib/herdr-agents.ts` — that path is retired; agent registry lives in kimi-toolchain only.

**Machine project discovery:** optional `~/.config/dx/projects.json` (template at `config/dx/templates/projects.json`) lists repos for `herdr-doctor` project profile scans. Installed on first `install.sh` if missing. Include at least `kimi-toolchain` and `dx-config` in `topProjects`; richer DX discovery fields (`packageName`, `discovery`, …) are optional.

---

## Global machine prefs (`config/dx/herdr.toml`)

Canonical upstream references:

- [configuration.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/configuration.mdx) — terminal defaults, worktrees, `[remote]`, UI, keys
- [session-state.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/session-state.mdx) — what survives detach/restart/handoff
- [persistence-remote.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/persistence-remote.mdx) — detach, named sessions, `herdr --remote`, direct attach

| Section | Key | This machine | Upstream default | Notes |
|---------|-----|--------------|------------------|-------|
| `[terminal]` | `shell_mode` | `auto` | `auto` | Login shells on macOS so `path_helper` and Homebrew PATH run in new panes; non-login elsewhere. Spawn wrappers and command panes keep their own execution paths. |
| `[terminal]` | `new_cwd` | `follow` | `follow` | New panes/tabs/workspaces inherit source cwd; CLI `--cwd` still wins. |
| `[worktrees]` | `directory` | `~/Projects/herdr-worktrees` | `~/.herdr/worktrees` | Sibling-style checkouts under `<dir>/<repo>/<branch-slug>`. Grouped under parent workspace in sidebar; closing parent closes the Herdr group, not the checkout. Delete via **Delete worktree checkout...** on a child row. |
| `[remote]` | `manage_ssh_config` | `true` | `true` | `herder-remote` / `herdr --remote`: temp SSH config (user config first) with keepalive fallback; `--remote-keybindings server` for remote keys; `--handoff` experimental. |
| `[session]` | `resume_agents_on_restore` | `true` | `true` | Native session resume for integrated agents after server restart; Grok is screen-only — no resume. |
| `[experimental]` | `pane_history` | `false` | `false` | Off — pane output can contain secrets. When enabled, history lives in `~/.config/herdr/session-history.json`. |

After edits: `herdr server reload-config` (most UI prefs hot-reload; startup-only settings need restart).

---

## Official Herdr vs This Machine's DX Layer

| Topic | Official ([herdr.dev/docs](https://herdr.dev/docs/)) | This DX Layer (`config/dx`) | Notes |
|-------|------------------------------------------------------|-----------------------------|-------|
| Agent detection model | Full table + status authority rules (process + screen manifest + optional hooks) | Simplified 3-tier table (Lifecycle / Session / Screen) | Local version is compressed but directionally correct |
| Integrations | Per-agent install paths + minimum versions | `herdr.json` `required` list + `herdr-doctor` enforcement | Doctor enforces the subset we actually use |
| Spawn from CLI / keyboard | `herdr agent start … -- claude`, `herdr agent attach` | `herdr-spawn-*` wrappers + keybindings + `herdr-project` | Our layer adds keyboard + project bootstrap convenience |
| Control surface | Upstream `SKILL.md` ([agent-guide](https://herdr.dev/agent-guide.md)) + full socket API | Local `config/agents/skills/herdr/` symlinked to selected agents | We only symlink to agents we expect to self-control panes |
| Session restore | Full matrix + min versions (kimi v3, codex v5, claude v6, etc.) | Matches `MIN_INTEGRATION_VERSIONS` + `[session] resume_agents_on_restore` | Good parity |
| Debugging state mismatches | `herdr agent explain <pane>` | Documented below + control skill recipe | See [Debugging](#debugging-wrong-agent-state) |
| Agent coverage | 15+ agents (pi, omp, opencode, kilo, copilot, devin, droid, qodercli, amp, kiro, …) | Only our 6 daily drivers | Intentional focus; upstream knows the rest |
| Local manifest overrides | `~/.config/herdr/agent-detection/<agent>.toml` | Not currently used | Available if we need to tweak detection rules |
| Plugins / worktrees / marketplace | Full socket API surface | Control skill covers workspace/tab/pane only | Plugins not yet needed in our workflow |

**Key conceptual clarification** (from [agents.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/agents.mdx)):

- **Lifecycle authority** (kimi, hermes when hooks installed): integration reports `idle` / `working` / `blocked` + session ID; Herdr does **not** also run screen manifest fallback for that pane.
- **Session identity only** (codex, claude, cursor): hooks provide native session restore; **state still comes from the live bottom-buffer screen snapshot**, not hooks — hooks can miss permission approvals and interrupts.
- **Screen only** (grok): manifest detection only; no integration role. DX still provides spawn wrapper + keybinding.
- **Blocked** is strict for screen-manifest agents: only when bottom-buffer matches known approval UI; otherwise `idle` with `default_known_agent_idle_fallback` in explain output.

Upstream pages (source → rendered):

| Topic | Source | Rendered |
|-------|--------|----------|
| Configuration | [configuration.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/configuration.mdx) | [herdr.dev/docs/configuration](https://herdr.dev/docs/configuration/) |
| Agents & status authority | [agents.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/agents.mdx) | [herdr.dev/docs/agents](https://herdr.dev/docs/agents/) |
| Persistence & remote | [persistence-remote.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/persistence-remote.mdx) | [herdr.dev/docs/persistence-remote](https://herdr.dev/docs/persistence-remote/) |
| Session state & restore | [session-state.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/session-state.mdx) | [herdr.dev/docs/session-state](https://herdr.dev/docs/session-state/) |
| Integrations | — | [herdr.dev/docs/integrations](https://herdr.dev/docs/integrations/) |
| CLI automation | — | [herdr.dev/docs/socket-api](https://herdr.dev/docs/socket-api/) |
| Agent onboarding | — | [herdr.dev/agent-guide.md](https://herdr.dev/agent-guide.md) |
| Upstream control skill | [SKILL.md](https://github.com/ogulcancelik/herdr/blob/master/SKILL.md) | — |

```
Herdr binary
  ├─ screen manifests (bundled + remote + optional local override)
  ├─ integration hooks (per-agent install)
  └─ CLI / socket API
        ↑
DX layer (machine policy only)
  ├─ herdr-spawn-* wrappers + keys.command
  ├─ herdr-project primaryAgent / bootstrap
  ├─ herdr-doctor required integrations + min versions
  └─ control skill → ~/.grok|codex|claude/skills/herdr
```

---

## Three Wiring Layers (This Machine)

| Layer | Purpose | Where Defined | Applies To |
|-------|---------|---------------|------------|
| Integration hooks | Lifecycle + session restore / identity | `herdr.json` + `herdr-doctor` | kimi, hermes, codex, claude, cursor |
| Screen detection | idle/working/blocked from terminal output | Agent manifests (remote + optional local overrides) | All 6 |
| DX spawn path | Launch binary from pane with correct PATH | `kimi-toolchain/src/lib/herdr-agents.ts` → `herdr-spawn-*` + keybindings + `herdr-project` | codex, kimi, hermes, grok, claude (cursor via CLI) |

---

## Canonical Registry (`kimi-toolchain/src/lib/herdr-agents.ts`)

```ts
export const AGENT_COMMANDS: Record<string, string[]> = {
  codex: ["codex"],
  kimi: ["kimi"],
  grok: ["grok"],
  hermes: ["hermes"],
  claude: ["claude"],
  cursor: ["cursor-agent"],
};

export const REQUIRED_INTEGRATIONS = ["codex", "kimi", "hermes", "claude", "cursor"] as const;
export const SPAWN_AGENTS = ["codex", "kimi", "hermes", "grok", "claude"] as const;
export const SCREEN_DETECTED_AGENTS = ["grok"] as const;
```

`resolveAgentArgv()` in `herdr-project` accepts any name from `AGENT_COMMANDS`.

**Maintenance rule**: Treat `herdr-agents.ts` as the single source of truth for command names, required integrations, and spawnable agents.

---

## Integration Tiers (This Machine)

| Tier | Agents | Behavior |
|------|--------|----------|
| **Lifecycle authority** | kimi, hermes | Hooks authoritative when installed and reporting; no parallel screen fallback. Falls back to screen manifest when hooks absent. |
| **Session identity** | codex, claude, cursor | Integration provides session ID/restore only; **state from bottom-buffer screen manifest** |
| **Screen only** | grok | Manifest detection only. No integration hook. Full DX spawn + keybinding still provided. |

Detection reads the **live bottom of the pane buffer**, not the scrolled viewport. Scrollback in Herdr does not change what manifests match.

---

## Agent Capabilities Matrix (This Machine)

| Agent | Official Integration Role | Official State Authority | This Machine Spawn/Key | Control Skill Symlink | Daily Driver | Notes |
|-------|---------------------------|--------------------------|------------------------|----------------------|--------------|-------|
| **kimi** | Lifecycle + session | Hooks (when installed) | `herdr-spawn-kimi` + `alt+k` | `~/.kimi-code/skills/herdr` | Primary | Full featured |
| **hermes** | Lifecycle + session | Plugin/hooks (when installed) | `herdr-spawn-hermes` + `alt+h` | `~/.hermes/skills/herdr` | Primary | Full featured |
| **codex** | Session only | **Screen manifest** | `herdr-spawn-codex` + `alt+c` | `~/.codex/skills/herdr` | Primary | State is screen-detected |
| **claude** | Session only | **Screen manifest** | `herdr-spawn-claude` + `alt+l` | `~/.claude/skills/herdr` | Secondary | Full featured |
| **cursor** | Session only | **Screen manifest** | CLI-only (`herdr pane run cursor-agent`) | ✗ | Via profile/CLI | No spawn wrapper or key (by design) |
| **grok** | None | **Screen manifest only** | `herdr-spawn-grok` + `alt+g` | `~/.grok/skills/herdr` | Primary | Correctly screen-only for integration |

**Control skill** (`config/agents/skills/herdr/SKILL.md`) teaches pane/workspace control commands. Symlinked into Grok, Codex, Claude, Kimi, and Hermes skill dirs.

Local copy: `~/.config/agents/skills/herdr/SKILL.md` (deployed from `config/agents/skills/herdr/`).

---

## How to Launch Agents (This Machine)

| Method | Usage |
|--------|-------|
| **Keyboard** (daily drivers) | `prefix+alt+c` / `alt+k` / `alt+h` / `alt+g` / `alt+l` (prefix = `ctrl+b`) |
| **Project bootstrap** | `primaryAgent` / `secondaryAgents` in project profile (any name from `AGENT_COMMANDS`) |
| **Spawn wrapper** | `~/.local/bin/herdr-spawn-<agent>` |
| **CLI / one-off** | `herdr pane run w1:p1 "cursor-agent"` or upstream `herdr agent start … -- claude` |
| **Debug state** | `herdr agent explain <pane-id>` — see below |

---

## Config Symlink Chain

```
~/.config/herdr/config.toml  →  ~/.config/dx/herdr.toml  →  ~/dx-config/config/dx/herdr.toml
```

| Layer | Path | Role |
|-------|------|------|
| Herdr | `~/.config/herdr/config.toml` | What Herdr reads |
| DX | `~/.config/dx/herdr.toml` | What DX tooling reads |
| Git | `~/dx-config/config/dx/herdr.toml` | Version-controlled source |

**Do not flatten** this chain. The middle hop lets DX (`global-config.json`, `herdr-doctor`, spawn wrappers, `herdr-project`) own `~/.config/dx/` independently of Herdr's canonical path. See `~/kimi-toolchain/CODE_REFERENCES.md`.

## Layout

| Path | Role |
|------|------|
| `~/.config/dx/herdr.toml` | DX ownership surface (theme, keys, notifications) |
| `~/.config/dx/herdr.json` | Machine manifest for doctors and agents |
| `~/.config/herdr/config.toml` | Symlink → `../dx/herdr.toml` |
| `~/.config/herdr/` | Runtime only: socket, logs, `session.json` |
| `~/.config/shell/herdr.sh` | Shell helpers (`herder`, `herder-remote`, …) |
| `~/.config/agents/skills/herdr/` | Canonical Herdr control skill |
| `~/.kimi-code/tools/herdr-*.ts` | Synced CLIs (source in kimi-toolchain `src/bin/`) |
| `~/.kimi-code/lib/herdr-agents.ts` | Synced agent registry (source in kimi-toolchain `src/lib/`) |
| `~/.local/bin/herdr-{doctor,project,spawn}` | PATH wrappers → `~/.kimi-code/tools/` |
| `~/.local/bin/herdr-spawn-*` | Keybinding stubs (generated by kimi-toolchain `install-wrappers`) |

## Commands

```sh
herder                      # attach or start default session
herder ~/Projects/foo       # start in project directory
herder-status               # client + server health
herder-agents               # list detected agents
herder-stop                 # stop server and panes
herder-edit-config          # edit dx/herdr.toml and reload
herder-maintain             # brew upgrade + manifest refresh + doctor
herdr-doctor                # integration health check
herdr-doctor --json
herdr-doctor --fix          # refresh stale agent manifests
herdr-quickref              # workspaces, agents, key cheats (also: herder-quickref)
```

## Keyboard (prefix = ctrl+b)

| Action | Keys |
|--------|------|
| Session navigator | `g` |
| Detach | `q` |
| Split right / down | `v` / `-` |
| New tab | `c` |
| Focus agent N | `alt+1` … `alt+9` |
| Open notification | `o` |
| Last pane | `` ` `` |
| Start codex / kimi / hermes / grok / claude | `alt+c` / `alt+k` / `alt+h` / `alt+g` / `alt+l` |

Agent keybindings use `~/.local/bin/herdr-spawn-*` wrappers so binaries resolve from login-shell PATH inside Herdr panes.

## Session state and restore

Canonical upstream: [session-state.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/session-state.mdx) ([rendered](https://herdr.dev/docs/session-state/)). Herdr has five persistence paths; they solve different problems.

### What survives

| Case | Processes keep running | Layout returns | Recent screen returns | Agent conversation resumes |
|------|------------------------|----------------|-----------------------|----------------------------|
| Detach and reattach (`prefix+q`, then `herdr`) | Yes | Yes | Yes — live terminal | Yes — process never stopped |
| Server restart | No | Yes — snapshot | Only with `pane_history = true` | Only with native agent session restore |
| Update without `--handoff` | Compatible servers may keep running | Yes after restart | Only with pane history | Only with native agent restore |
| Update with `--handoff` | Best effort | Yes | Yes if handoff succeeds | Yes if handoff succeeds |

**This machine:** Homebrew install — use `herder-maintain` / `brew upgrade herdr`, not `herdr update`. No live handoff via package manager; server restart follows the snapshot + native-restore path.

### Paths (upstream names)

1. **Live persistence** — `prefix+q` detach keeps the server and all pane processes running. Strongest path; use for daily work.
2. **Snapshot restore** — after server stop/start, workspaces/tabs/panes/cwd/layout/focus return; arbitrary processes do not. Unsupported panes reopen as new shells in saved directories.
3. **Pane screen history** — `[experimental] pane_history = true` replays recent terminal contents after restart (not the old process). **Off here** — treat `~/.config/herdr/` like terminal history if enabled.
4. **Native agent session restore** — `[session] resume_agents_on_restore = true` (default). Integration-reported session IDs restart supported agents after attach (across workspaces/tabs once the client provides terminal size and theme context — no per-pane focus needed). If native restore applies, it wins over pane history for that pane. OMP v2 reports state but not session refs for restore.
5. **Live handoff** — experimental `herdr update --handoff` / `herdr --remote workbox --handoff`; not available on Homebrew installs. Plain `herdr update` and plain `herdr --remote` use normal stop/restart.

### Native restore — daily agents on this Mac

`herdr integration status` — all required integrations current as of 2026-06-16:

| Agent | Min integration | Resume command | Status |
|-------|-----------------|----------------|--------|
| kimi | v3 | `kimi --session <id>` | current (v3) |
| hermes | v2 | `hermes --resume <id>` | current (v2) |
| codex | v5 | `codex resume <id>` | current (v5) |
| claude | v6 | `claude --resume <id>` | current (v6) |
| cursor | v1 | `cursor-agent --resume <id>` | current (v1) |
| grok | — | — | Screen manifest only; no native session restore |

Stale, missing, or unsupported session refs restore as shells in the saved pane directory. Reinstall with `herdr integration install <agent>` when doctor flags version drift.

Runtime snapshot: `~/.config/herdr/session.json` (never commit). Ephemeral sockets/logs live alongside it.

### Public IDs

Workspaces, tabs, and panes use stable handles: `w1`, `w1:t1`, `w1:p1` (v0.7.0+). Closed ids do not get reused. Re-read ids from `herdr workspace list`, `herdr tab list`, or `herdr pane list` before targeting a pane in scripts.

## Persistence and remote access

Canonical upstream: [persistence-remote.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/persistence-remote.mdx) ([rendered](https://herdr.dev/docs/persistence-remote/)). For survival matrix after server stop, see [Session state and restore](#session-state-and-restore).

| Workflow | Command | Notes |
|----------|---------|-------|
| Detach client | `prefix+q` (`ctrl+b q`) | Server + panes keep running |
| Reattach | `herder` or `herdr` | Default session |
| Stop server + panes | `herdr server stop` | Full stop — unlike detach |
| Named sessions | `herdr session list` / `attach` / `stop` / `delete` | Independent servers; shared global config |
| Remote thin client | `herder-remote workbox` | Local UI over SSH; local keybindings snapshot at attach time |
| Remote named session | `herdr --remote workbox --session agents` | |
| Remote live handoff | `herdr --remote workbox --handoff` | Experimental; Homebrew local install still upgrades via brew |
| Direct agent attach | `herdr agent attach reviewer` | One terminal, not full UI; `prefix+q` detach |
| Debug escape hatch | `herdr --no-session` | No background server — rarely needed |

Remote attach: `[remote] manage_ssh_config = true` (see global prefs). `HERDR_REMOTE_BINARY` overrides binary copied to remote for local/custom builds.

## Detection Manifests

Bundled manifests ship in the binary. Herdr also fetches remote rule updates from herdr.dev into the state directory and reloads the in-memory cache automatically. Manual refresh:

```sh
herdr server update-agent-manifests   # or: herder-maintain / herdr-doctor --fix
```

Local overrides (optional) **always win** over remote/bundled:

```
~/.config/herdr/agent-detection/<agent>.toml
```

Without a local override, Herdr uses the newer compatible manifest between cached remote and bundled. Remote manifests patch rules for known agents only — new agent types still need a binary update. After editing a local override: `herdr server reload-agent-manifests` or restart. See [agents.mdx → Detection manifests](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/agents.mdx).

## Debugging Wrong Agent State

When a pane shows unexpected `idle`, `working`, or `blocked`:

```sh
herdr agent list
herdr agent explain w1:p1
herdr agent explain w1:p1 --json
```

Explain output shows agent, final state, lifecycle-authority skip, manifest source/version, cached remote version, local override shadowing, remote update status, matched rule, evidence flags, matcher/region evidence, and idle-fallback reason (`default_known_agent_idle_fallback` when no rule matched). For **codex/claude/cursor** panes, start with screen manifest — not integration hook state.

Offline transcript check:

```sh
herdr agent explain --file screen.txt --agent codex --json
```

When `HERDR_ENV=1`, you are inside a Herdr pane — do not nest `herdr`.

## Control Skill Installation (`install.sh`)

```sh
~/.grok/skills/herdr        → ~/.config/agents/skills/herdr
~/.codex/skills/herdr       → ~/.config/agents/skills/herdr
~/.claude/skills/herdr      → ~/.config/agents/skills/herdr
~/.kimi-code/skills/herdr   → ~/.config/agents/skills/herdr
~/.hermes/skills/herdr      → ~/.config/agents/skills/herdr
```

## Workspaces, git, and standard pane layout

### One workspace = one repo checkout = one branch

Each Herdr workspace maps to **one git working tree** at a single branch. All panes start at that repo root (`cwd`); agents and shells share the same checkout unless you manually `cd`.

| Workspace | Label | Repo path | Typical branch | Remote |
|-----------|-------|-----------|----------------|--------|
| kimi-toolchain | kimi-toolchain | `~/kimi-toolchain` | one branch per workspace | GitHub `origin` |
| dx-config | dx-config | `~/dx-config` | `main` | `origin` → `git@github.com:brendadeeznuts1111/dx-config.git` |

**Do not** mix multiple branches in one workspace. For parallel branch work, use **Herdr worktrees** (`herdr worktree create` / `open`) — each linked checkout becomes its own workspace. Codex worktrees under `~/.codex/worktrees/` are separate from Herdr unless you open them explicitly.

### Standard pane layout (target)

```
Workspace (one repo @ one branch)
├── Tab "agents"
│   ├── primary agent  (kimi / grok)
│   ├── shell          (split right — git, bootstrap, manual)
│   └── secondary      (codex / claude)
└── Tab "shell" (optional)
    └── herdr-quickref + manual commands
```

Set in project profile: `primaryAgent`, `secondaryAgents`, `shellPane`, `shellSplit`, `[[herdr.tabs]]`, `bootstrap` (include `git status -sb` + `herdr-quickref`).

### Workspace types on this Mac

| Type | Example | Primary | Secondary | Bootstrap |
|------|---------|---------|-----------|-----------|
| **Code repo** | kimi-toolchain | `kimi` | `codex` | `dx config`, `git status -sb`, `herdr-quickref`, `kimi-doctor --quick` |
| **Config repo** | dx-config | `grok` | `claude` | `herdr-doctor`, `git status -sb`, `herdr-quickref`, `dx context` |

Entry: `herder ~/kimi-toolchain` or `herder ~/dx-config` — never `$HOME`.

## Project Profiles

Per-repo Herdr layout — same discovery order as `dx config`:

1. `.dx/herdr.toml` (project-only profile)
2. `[herdr]` in `dx.config.toml`
3. `.dx/config.toml` / `.config/dx.toml`

Templates (machine):

| Repo type | Template | Live reference |
|-----------|----------|----------------|
| **Code / toolchain** | `~/.config/dx/templates/herdr.project.toml` | `~/kimi-toolchain/dx.config.toml` `[herdr]` |
| **Config / dotfiles** | `~/.config/dx/templates/herdr.project.config.toml` | `~/dx-config/.dx/herdr.toml` |

Toolchain code repos should prefer `kimi-fix <path> --profile toolchain` over hand-copying — see `~/kimi-toolchain/TEMPLATES.md` (scaffold profiles + migration). Effect gates in code repos: **`kimi-doctor --effect-gates`** (not `bun run doctor`, not `herdr-doctor`).

**Syntax:** flat `.dx/herdr.toml` uses `[[tabs]]`; nested `dx.config.toml` uses `[[herdr.tabs]]`.

### Code repo scaffold v2 — Alternative A locked in

**Status:** default for new Bun code repos on this machine (2026-06-16). Source: `config/dx/templates/herdr.project.toml` (`schemaVersion = 2`).

The **test** tab uses `grok --role test-agent` so Grok runs as a first-class Herdr agent — not a plain shell command. **Alternative B** (shell wrapper around test output) is **disabled**; do not use it in new profiles.

| Benefit | Practice |
|---------|----------|
| Agent semantics | Pane appears in `herdr agent list`; supports `wait agent-status`, `agent attach`, `agent send` |
| Sidebar observability | `pane report-agent --custom-status` works (e.g. "running tests", "3 failing") |
| Orchestrator reactivity | `watch-events` can react to test agent `pane.agent_status_changed` alongside `effect.gates.changed` |
| Stack consistency | Same pattern as `kimi`, `finish-work-reviewer`, and other named agents |

**When to use `grok --role` vs plain `command`:**

| Tab kind | Command pattern | Why |
|----------|-----------------|-----|
| Dev server / REPL / one-shot check | `bun run dev`, `bun repl`, `bun run check:fast` | No agent lifecycle — `pane run` is correct |
| Long-running test watcher | `grok --role test-agent --cwd . -- bun run scripts/test-agent.ts --watch` | Agent semantics + status reporting |
| Doctor / shell / quickref | `kimi-doctor --quick`, `git status -sb; herdr-quickref` | Operational shells, not agents |

`herdr-project` today starts extra tabs via `pane run` on the tab `command`. Commands that begin with `grok --role` should eventually route through `herdr agent start` + `agent rename` + optional `report-agent` during reconcile/bootstrap (tracked in kimi-toolchain `herdr-project-reconcile`). Until that lands, the v2 command string is still the **authoritative profile default** — reconcile will catch up.

**Default v2 tab block** (Bun app; adjust or drop tabs your repo does not need):

```toml
[[tabs]]
label = "dev"
command = "bun run dev"

[[tabs]]
label = "check"
command = "bun run check:fast"

[[tabs]]
label = "test"
command = "grok --role test-agent --cwd . -- bun run scripts/test-agent.ts --watch"

[[tabs]]
label = "repl"
command = "bun repl"
```

Add `doctor` + `shell` ops tabs from the template for daily-driver layout. Toolchain repos (`kimi-fix --profile toolchain`) also get `reviewer` + `[finishWork]` — see `~/kimi-toolchain/TEMPLATES.md` and [finish-work close-loop](https://github.com/brendadeeznuts1111/kimi-toolchain/blob/main/docs/finish-work-close-loop.md).

Config repo example (flat `.dx/herdr.toml`):

```toml
schemaVersion = 1
enabled = true
workspaceLabel = "dx-config"
primaryAgent = "grok"
secondaryAgents = ["claude"]
shellPane = true
shellSplit = "right"
bootstrap = ["herdr-doctor", "git status -sb", "herdr-quickref", "dx context 2>/dev/null || true"]

[[tabs]]
label = "doctor"
command = "herdr-doctor 2>/dev/null || true"

[[tabs]]
label = "shell"
command = "git status -sb; herdr-quickref"
```

```sh
herdr-project discover .          # show resolved profile
herdr-project status .            # workspace already open?
herdr-project bootstrap .         # create/focus workspace + agents
herdr-project bootstrap . --force # re-run bootstrap shell commands
herdr-project scaffold .          # write .dx/herdr.toml
herder ~/kimi-toolchain           # auto-bootstraps when [herdr] is enabled
```

Re-running `bootstrap` on an existing workspace is idempotent: agents are skipped if present, shell panes are reused, and bootstrap commands run only on first workspace creation (use `--force` to replay them).

Bootstrap commands run in the shell pane as **one** `env PATH=… cmd1 && cmd2 && …` line so PATH is not corrupted by repeated `export PATH` prefixes. `herdr-project` prepends `~/.local/bin`, `~/.kimi-code/bin`, `~/.bun/bin`, and Homebrew to the pane PATH.

### Live session tweaks (correct syntax)

```sh
herdr tab rename wB:t1 "agents"    # tab id required — get ids from: herdr tab list --workspace <ws>
herdr pane close wB:p4               # pane id required — list with: herdr pane list
herder ~/kimi-toolchain              # recreate workspace after close
```

Profile for kimi-toolchain lives in `~/kimi-toolchain/dx.config.toml` under `[herdr]` (not `.herdr.toml`). There is no `--profile` flag on `herdr-project`.

## Updates

Homebrew install — run `herder-maintain` or `brew upgrade herdr`, not `herdr update`.

```sh
herder-maintain
```

## Doctors

```sh
herdr-doctor
dxherdr
dx audit    # global-context-doctor includes herdr checks
```

Run `herdr-doctor` regularly. Update this document whenever wiring or upstream behavior changes.

---

## Current Gaps & Recommended Fixes

1. ~~**Docs** — Official vs DX comparison + state-authority clarification.~~ Done.
2. ~~**Claude keybinding** — `prefix+alt+l` in `herdr.toml`.~~ Done.
3. ~~**Kimi / Hermes control skill** — `install.sh` + `herdr.json` agentSkills.~~ Done.
4. ~~**Cursor** — CLI-only (`herdr pane run cursor-agent` / `primaryAgent = "cursor"`).~~ Decided.
5. ~~**Control skill** — `herdr agent explain` in `config/agents/skills/herdr/SKILL.md`.~~ Done.
6. **Optional** — Add local manifest overrides in `~/.config/herdr/agent-detection/` if detection rules need tweaking.
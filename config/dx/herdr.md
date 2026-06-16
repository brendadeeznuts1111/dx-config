# Herdr — Local DX Configuration & Agent Reference (This Machine)

Canonical upstream docs: [configuration.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/configuration.mdx)

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

**Key conceptual clarification**:

For **codex**, **claude**, and **cursor**:

- The integration hook primarily provides **session identity** and **restore** capability.
- **Idle / working / blocked** state is **still detected from the screen manifest** (terminal output), **not** from the integration hook.
- State authority remains screen-based for these three even when the integration is installed.

**Grok** is screen-manifest only (no integration role). DX still provides full spawn wrapper + keybinding.

Upstream pages:

| Topic | Link |
|-------|------|
| Agents and status authority | [herdr.dev/docs/agents](https://herdr.dev/docs/agents/) |
| Integration install per agent | [herdr.dev/docs/integrations](https://herdr.dev/docs/integrations/) |
| Detach, restart, restore | [herdr.dev/docs/session-state](https://herdr.dev/docs/session-state/) |
| CLI automation | [herdr.dev/docs/socket-api](https://herdr.dev/docs/socket-api/) |
| Agent onboarding prompt | [herdr.dev/agent-guide.md](https://herdr.dev/agent-guide.md) |
| Upstream control skill | [github.com/ogulcancelik/herdr/SKILL.md](https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md) |

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
| **Lifecycle authority** | kimi, hermes | Full hooks report idle/working/blocked + session ID when integration installed; screen manifest fallback otherwise |
| **Session identity** | codex, claude, cursor | Integration provides session ID/restore; **state still comes from screen manifest** |
| **Screen only** | grok | Manifest detection only. No integration hook. Full DX spawn + keybinding still provided. |

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

## Persistence & Public IDs

| Case | Processes | Layout | Agent conversation |
|------|-----------|--------|-------------------|
| Detach (`ctrl+b q`) | Keep running | Yes | Yes — processes never stopped |
| Server restart | Stopped | Restored from snapshot | Resumes when integration reports session id |
| `brew upgrade herdr` | Stopped on restart | Restored | Same as server restart |

`resume_agents_on_restore = true` (default) uses official integration hooks. `pane_history` stays **off** — pane output can contain secrets.

Workspaces, tabs, and panes use stable handles: `w1`, `w1:t1`, `w1:p1` (v0.7.0+). Closed ids do not get reused. Re-read ids from `herdr workspace list`, `herdr tab list`, or `herdr pane list` before targeting a pane in scripts.

## Detection Manifests

Screen rules live in Herdr's manifest cache (bundled + remote). Refresh manually:

```sh
herdr server update-agent-manifests   # or: herdr-doctor --fix
```

Local overrides (optional) shadow remote/bundled rules:

```
~/.config/herdr/agent-detection/<agent>.toml
```

After editing a local override: `herdr server reload-agent-manifests` or restart the server. See [Agents → Detection manifests](https://herdr.dev/docs/agents/#detection-manifests).

## Debugging Wrong Agent State

When a pane shows unexpected `idle`, `working`, or `blocked`:

```sh
herdr agent list
herdr agent explain w1:p1
herdr agent explain w1:p1 --json
```

Explain output shows manifest source and version, whether a lifecycle authority skipped screen detection, matched rule, and idle-fallback reason. For **codex/claude/cursor** panes, start by checking screen manifest match — not integration hook state.

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
# Herdr (DX integration)

Herdr is the global agent terminal multiplexer on this Mac. User-owned settings are versioned in `~/dx-config` and deployed to the DX hub; runtime state stays in `~/.config/herdr/`.

## Config symlink chain

```
~/.config/herdr/config.toml  →  ~/.config/dx/herdr.toml  →  ~/dx-config/config/dx/herdr.toml
```

Three layers, three responsibilities:

| Layer | Path | Role |
|-------|------|------|
| Herdr | `~/.config/herdr/config.toml` | What Herdr reads |
| DX | `~/.config/dx/herdr.toml` | What DX tooling reads |
| Git | `~/dx-config/config/dx/herdr.toml` | Version-controlled source |

**Do not flatten** this chain. The middle hop lets DX (`global-config.json`, `herdr-doctor`, spawn wrappers, `herdr-project`) own `~/.config/dx/` independently of Herdr's canonical path. Documented in `~/kimi-toolchain/CODE_REFERENCES.md`.

## Layout

| Path | Role |
|------|------|
| `~/.config/dx/herdr.toml` | DX ownership surface (theme, keys, notifications) |
| `~/.config/dx/herdr.json` | Machine manifest for doctors and agents |
| `~/.config/herdr/config.toml` | Symlink → `../dx/herdr.toml` (Herdr's expected path) |
| `~/.config/herdr/` | Runtime only: socket, logs, `session.json` |
| `~/.config/shell/herdr.sh` | Shell helpers (`herder`, `herder-remote`, …) |
| `~/.config/agents/skills/herdr/` | Canonical Herdr control skill |
| `~/.config/dx/lib/herdr-agents.ts` | Shared agent path resolution |
| `~/.local/bin/herdr-spawn-*` | Keybinding-safe agent launchers |

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
| Start codex / kimi / hermes / grok | `alt+c` / `alt+k` / `alt+h` / `alt+g` |

Agent keybindings use `~/.local/bin/herdr-spawn-*` wrappers so binaries resolve from your login-shell PATH inside Herdr panes.

## Foundation

### Persistence

| Case | Processes | Layout | Agent conversation |
|------|-----------|--------|-------------------|
| Detach (`ctrl+b q`) | Keep running | Yes | Yes — processes never stopped |
| Server restart | Stopped | Restored from snapshot | Resumes when integration reports session id |
| `brew upgrade herdr` | Stopped on restart | Restored | Same as server restart |

`resume_agents_on_restore = true` (default) uses official integration hooks. `pane_history` stays **off** — pane output can contain secrets.

### Integration tiers

| Tier | Agents | Behavior |
|------|--------|----------|
| Lifecycle authority | kimi, hermes | Hooks report idle/working/blocked + session id |
| Session identity | codex, claude, cursor | Hooks report session id; screen detection for state |
| Screen only | grok | Manifest detection only; spawn via `herdr-spawn-grok` |

### Public IDs (v0.7.0+)

Workspaces, tabs, and panes use stable handles: `w1`, `w1:t1`, `w1:p1`. Closed ids do not get reused by later resources. Re-read ids from `herdr workspace list`, `herdr tab list`, or `herdr pane list` before targeting a pane in scripts.

## Agents

Integrations installed for: codex, kimi, hermes, claude, cursor.

- Kimi and Hermes report authoritative lifecycle state.
- Codex and Claude report session identity for restore after server restart.
- Grok is screen-detected only — no `herdr integration install grok`.
- When `HERDR_ENV=1`, you are inside a Herdr pane — do not nest `herdr`.

Skill source: `~/.config/agents/skills/herdr/SKILL.md`

## Updates

Homebrew install — run `herder-maintain` or `brew upgrade herdr`, not `herdr update`.

Recommended after upgrade:

```sh
herder-maintain
```

## Project profiles

Per-repo Herdr layout lives in DX project config — same discovery order as `dx config`:

1. `.dx/herdr.toml` (project-only profile)
2. `[herdr]` in `dx.config.toml`
3. `.dx/config.toml` / `.config/dx.toml`

Template: `~/.config/dx/templates/herdr.project.toml`

```toml
[herdr]
enabled = true
workspaceLabel = "my-app"
primaryAgent = "kimi"
secondaryAgents = ["codex"]
shellPane = true
bootstrap = ["dx config --project ."]
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

## Doctors

```sh
herdr-doctor
dxherdr
dx audit    # global-context-doctor includes herdr checks
```
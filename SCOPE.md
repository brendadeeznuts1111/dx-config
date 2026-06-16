# dx-config — scope and boundaries

Machine-wide Herdr and DX configuration for this Mac. **Dotfiles repo — not a code repo.**

Remote: `git@github.com:brendadeeznuts1111/dx-config.git`

---

## Purpose

Version-control **how tools attach to this machine**. Implement the tools in `kimi-toolchain`; wire them here.

| | `kimi-toolchain` | `dx-config` |
|---|---|---|
| Purpose | Code — the tools | Config — how tools are wired to this machine |
| Change cadence | Features, semver releases | New machine, agent, integration |
| Blast radius | Every project using the toolchain | This user's environment only |

---

## What belongs here

### Global Herdr / DX (`config/dx/`)

| Path | Deployed to | Role |
|------|-------------|------|
| `herdr.toml` | `~/.config/dx/herdr.toml` | Theme, keys, spawn keybindings, UI |
| `herdr.json` | `~/.config/dx/herdr.json` | Machine manifest (integrations, wrappers, skills) |
| `herdr.md` | `~/.config/dx/herdr.md` | Agent matrix, workspace model, this Mac's reference |

| `templates/herdr.project.toml` | `~/.config/dx/templates/` | Scaffold for other repos' profiles |

### Shell helpers (`config/shell/`)

- Thin wrappers (`herder`, `herder-maintain`, `herder-quickref`) that delegate to `PATH`
- No business logic

### Control skill (`config/agents/skills/herdr/`)

- Teaches agents inside Herdr panes to use the `herdr` CLI
- `install.sh` symlinks into agent skill dirs (grok, codex, claude, kimi-toolchain runtime, hermes)

### Deploy stubs (`local/bin/`)

| Allowed | Examples |
|---------|----------|
| Spawn wrappers | `herdr-spawn`, `herdr-spawn-*` |
| Small helpers | `herdr-quickref` |


### Install (`scripts/install.sh`)

Symlink `config/` → `~/.config/`, copy `local/bin/` → `~/.local/bin/`, link Herdr config chain and skill symlinks.

### This repo's Herdr profile (`.dx/herdr.toml`)

dx-config is also a Herdr project (dotfiles workspace). Profile lives here because there is no `dx.config.toml` in a config-only repo.

---

## What does not belong here

| Item | Where it lives |
|------|----------------|
| `kimi-doctor`, governance, Bun CLIs | `kimi-toolchain` → sync to `~/.kimi-code/` |
| Per-code-repo `[herdr]` profiles | That repo's `dx.config.toml` (e.g. `~/kimi-toolchain`) |
| Herdr session state (sockets, `session.json`) | `~/.config/herdr/` — ephemeral |
| Integration hooks | Installed by `herdr integration install` into agent homes |
| Kimi MCP, sessions, `config.toml` | `~/.kimi-code/` runtime |
| Application source | Their own project repos |
| `projects.json` (machine discovery) | `~/.config/dx/` — optional template only |

---

## Three-layer config chain

Do not flatten. See `~/kimi-toolchain/CODE_REFERENCES.md`.

```
~/dx-config/config/dx/herdr.toml     ← git source (this repo)
        ↓ symlink
~/.config/dx/herdr.toml              ← DX tooling reads here
        ↓ symlink
~/.config/herdr/config.toml          ← Herdr binary reads here
```

Runtime state (`~/.config/herdr/session.json`, logs, sockets) is never committed.

---

## Workspace model (Herdr)

```
Machine
└── Herdr session
    ├── Workspace: kimi-toolchain   →  ~/kimi-toolchain  @ one branch
    ├── Workspace: dx-config        →  ~/dx-config       @ one branch
    └── (more via herder ~/project)
        └── Tab "agents": primary + shell + secondary
            Tab "shell" (optional): quickref / manual
```

- **One workspace = one git checkout = one branch**
- More branches → Herdr worktrees → separate workspaces
- Entry: `herder ~/kimi-toolchain` or `herder ~/dx-config` — never `$HOME`

Full reference: `config/dx/herdr.md`

---

## Herdr CLIs (kimi-toolchain)

`herdr-doctor`, `herdr-project`, and `herdr-spawn` are authored in `kimi-toolchain` (`src/bin/`, `src/lib/herdr-agents.ts`). Deployed via `bun run sync` → `~/.kimi-code/tools/` and `bun run install-wrappers` → `~/.local/bin/`. dx-config `install.sh` delegates to that flow and only copies thin `herdr-spawn-*` stubs plus `herdr-quickref`.

---

## Edit workflow

1. Change files under `config/` or `local/bin/` in this repo
2. `./scripts/install.sh` on fresh machine or after bin changes
3. `herdr server reload-config` after `herdr.toml` changes
4. `herdr-doctor` to verify

---

## Related docs

| Doc | Contents |
|-----|----------|
| `AGENTS.md` | Repo boundary summary for agents |
| `README.md` | Layout and quick start |
| `config/dx/herdr.md` | Agent matrix, keys, workspace types |
| `~/kimi-toolchain/CODE_REFERENCES.md` | Symlink chain rationale |

---

*Last updated: 2026-06-16*


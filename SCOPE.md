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
| `lib/herdr-agents.ts` | `~/.config/dx/lib/herdr-agents.ts` | Agent names, min integration versions *(migrate out)* |
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
| **Transitional** *(migrate out)* | `herdr-doctor`, `herdr-project` |

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

## Technical debt (transitional)

These violate "thin config + stubs only" but remain here until migrated to `kimi-toolchain`:

| File | Why it should move |
|------|-------------------|
| `local/bin/herdr-doctor` | Doctor implementation |
| `local/bin/herdr-project` | Bootstrap / workspace orchestration |
| `local/bin/herdr-spawn` | Shared spawn resolver (could stay as thin stub) |
| `config/dx/lib/herdr-agents.ts` | Shared types and PATH resolution |

`AGENTS.md` documents this as a known exception.

---

## Migration handoff (herdr tools → kimi-toolchain)

**Goal:** Author logic in kimi-toolchain; dx-config keeps TOML/JSON/shell/skill + `install.sh` references only.

### Phase 1 — Plan (no moves yet)

- [ ] List consumers: `install.sh`, `herdr.json`, `herdr-doctor`, shell `herder-*`
- [ ] Confirm `kimi-toolchain/src/lib/herdr-project-config.ts` stays in sync with `herdr-project`
- [ ] Decide install path: `bun run sync` → `~/.local/bin/` vs dx-config `install.sh` copy

### Phase 2 — Move source

| From (dx-config) | To (kimi-toolchain) |
|------------------|---------------------|
| `local/bin/herdr-doctor` | `src/cli/herdr-doctor.ts` or `tools/` |
| `local/bin/herdr-project` | `src/cli/herdr-project.ts` |
| `config/dx/lib/herdr-agents.ts` | `src/lib/herdr-agents.ts` |
| `local/bin/herdr-spawn` | thin wrapper or merged into spawn stubs |

### Phase 3 — Wire install

- [ ] `bun run sync` publishes binaries to `~/.local/bin/`
- [ ] dx-config `install.sh` stops copying migrated tools (or copies from sync output)
- [ ] dx-config `install.sh` keeps: symlinks, spawn stubs if still needed, skill links

### Phase 4 — Verify

```sh
herdr-doctor
herdr-project discover ~/kimi-toolchain
herder ~/dx-config
```

### Phase 5 — Cleanup dx-config

- [ ] Remove migrated sources from `local/bin/` and `config/dx/lib/`
- [ ] Update `AGENTS.md`, `README.md`, `SCOPE.md` debt section
- [ ] One commit in each repo

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

### Migration note

Upstream `kimi-toolchain` now includes `src/lib/herdr-project-config.ts` and integration tests — align with dx-config `local/bin/herdr-project` before Phase 2 moves.
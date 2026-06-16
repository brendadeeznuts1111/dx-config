# dx-config

Git source of truth for machine-wide DX and Herdr settings on this Mac.

Scope and boundaries: [SCOPE.md](SCOPE.md). Remote: `git@github.com:brendadeeznuts1111/dx-config.git`.

Runtime paths stay where tools expect them (`~/.config/dx/`, `~/.local/bin/`, etc.). This repo holds config and thin stubs; `scripts/install.sh` symlinks config and delegates Herdr CLIs to kimi-toolchain (`bun run sync` + `install-wrappers`).

## Config symlink chain

```
~/.config/herdr/config.toml  →  ~/.config/dx/herdr.toml  →  ~/dx-config/config/dx/herdr.toml
```

Herdr, DX, and git each own one layer. **Do not flatten** — see `~/kimi-toolchain/CODE_REFERENCES.md` (Herdr Config Symlink Chain) for the justification.

## Layout

```
dx-config/
├── config/dx/           # Herdr + DX hub files (deployed to ~/.config/dx/)
│   ├── herdr.toml
│   ├── herdr.json
│   ├── herdr.md
│   └── templates/
├── config/shell/        # Shell helpers (deployed to ~/.config/shell/)
├── config/agents/       # Agent skills (deployed to ~/.config/agents/)
├── local/bin/           # herdr-quickref only (CLIs + spawn stubs in kimi-toolchain)
└── scripts/
    ├── install.sh           # Symlink deploy + kimi-toolchain sync
    └── bootstrap-machine.sh # Fresh machine: sync + install + doctor
```

**Not in this repo** (runtime only):

- `~/.config/herdr/session.json`, sockets, logs
- `~/.local/state/herdr/` cached detection manifests
- Integration hooks installed by `herdr integration install`

## Workflow

```sh
# Fresh machine (kimi-toolchain cloned to ~/kimi-toolchain)
./scripts/bootstrap-machine.sh

# Config-only refresh (after dx-config edits)
./scripts/install.sh

# Edit here, then reload
herder-edit-config          # opens ~/.config/dx/herdr.toml (symlink into repo)
herdr server reload-config

# Health check
herdr-doctor
```

## Project profiles

Per-repo Herdr layout lives in each project's `dx.config.toml` `[herdr]` block (e.g. `~/kimi-toolchain/dx.config.toml`), not in this global repo. New code repos: start from `config/dx/templates/herdr.project.toml` (scaffold v2 — test tab uses `grok --role`; see `config/dx/herdr.md`).

Toolchain repos: `kimi-fix <path> --profile toolchain` scaffolds `[herdr]` + finish-work scripts from `~/kimi-toolchain/templates/scaffold/` (not this repo).

## Upstream Herdr docs

Machine reference: `config/dx/herdr.md` (deployed to `~/.config/dx/herdr.md`). Canonical API docs:

| Topic | Rendered | Upstream source |
|-------|----------|-----------------|
| Overview | [herdr.dev/docs](https://herdr.dev/docs/) | — |
| Configuration | [configuration](https://herdr.dev/docs/configuration/) | [configuration.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/configuration.mdx) |
| Agents & state authority | [agents](https://herdr.dev/docs/agents/) | [agents.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/agents.mdx) |
| Persistence & remote | [persistence-remote](https://herdr.dev/docs/persistence-remote/) | [persistence-remote.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/persistence-remote.mdx) |
| Session state & restore | [session-state](https://herdr.dev/docs/session-state/) | [session-state.mdx](https://github.com/ogulcancelik/herdr/blob/master/website/src/content/docs/session-state.mdx) |
| Socket API | [socket-api](https://herdr.dev/docs/socket-api/) | — |
| Integrations | [integrations](https://herdr.dev/docs/integrations/) | — |

Upstream docs live under `website/src/content/docs/` in the Herdr repo (not `src/content/docs/`). Also in `config/dx/herdr.json` under `docs` for programmatic discovery.

## Open in Cursor

Use `~/dx-config` as the workspace root — not `$HOME`.
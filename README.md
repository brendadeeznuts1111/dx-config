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
├── local/bin/           # herdr-spawn-* stubs, herdr-quickref (CLIs in kimi-toolchain)
└── scripts/install.sh   # Symlink deploy
```

**Not in this repo** (runtime only):

- `~/.config/herdr/session.json`, sockets, logs
- `~/.local/state/herdr/` cached detection manifests
- Integration hooks installed by `herdr integration install`

## Workflow

```sh
# First-time or after clone
./scripts/install.sh

# Edit here, then reload
herder-edit-config          # opens ~/.config/dx/herdr.toml (symlink into repo)
herdr server reload-config

# Health check
herdr-doctor
```

## Project profiles

Per-repo Herdr layout lives in each project's `dx.config.toml` `[herdr]` block (e.g. `~/kimi-toolchain/dx.config.toml`), not in this global repo.

## Open in Cursor

Use `~/dx-config` as the workspace root — not `$HOME`.
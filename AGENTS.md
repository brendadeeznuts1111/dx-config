# dx-config

Machine-wide DX and Herdr configuration for this Mac.

## Config symlink chain

`~/.config/herdr/config.toml` → `~/.config/dx/herdr.toml` → `~/dx-config/config/dx/herdr.toml`

Do not flatten. The DX middle hop is intentional — see `~/kimi-toolchain/CODE_REFERENCES.md`.

## Scope

- **This repo**: global Herdr config, spawn wrappers, shell helpers, control skill
- **Per-project**: `[herdr]` in each repo's `dx.config.toml` (e.g. `~/kimi-toolchain`)
- **Runtime**: `~/.config/herdr/` — ephemeral, never commit

## Edit workflow

1. Change files under `config/` or `local/bin/` in this repo
2. Run `./scripts/install.sh` if deploying to a fresh machine
3. `herdr server reload-config` after config changes
4. `herdr-doctor` to verify

## Commands

- `herder` — attach/start Herdr
- `herder ~/kimi-toolchain` — bootstrap project workspace
- `herder-maintain` — brew upgrade + manifest refresh + doctor
- `herdr-doctor` — integration health
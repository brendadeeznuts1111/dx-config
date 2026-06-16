# dx-config

Machine-wide DX and Herdr configuration for this Mac.

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
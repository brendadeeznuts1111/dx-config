# dx-config

Machine-wide DX and Herdr configuration for this Mac. Dotfiles repo — not a code repo.

Full scope: [SCOPE.md](SCOPE.md).

## Repo boundary (do not merge with kimi-toolchain)

| | `kimi-toolchain` | `dx-config` |
|---|---|---|
| Purpose | Code — the tools | Config — how tools are wired to this machine |
| Change cadence | Features, semver releases | New machine, agent, integration |
| Blast radius | Every project using the toolchain | This user's environment only |

**This repo may contain:** TOML/JSON/Markdown config, skills, shell helpers that delegate to PATH, `install.sh`, thin spawn stubs.

**This repo must not contain:** executable logic that implements doctors, bootstrap, or path resolution. That belongs in `kimi-toolchain` (or another code repo) and is installed to `~/.local/bin/` by sync or install — referenced, not authored here.

Herdr CLIs (`herdr-doctor`, `herdr-project`, `herdr-spawn`, `herdr-spawn-*`) are authored in `kimi-toolchain` and deployed via `bun run sync` + `install-wrappers`. This repo keeps `herdr-quickref` only. Fresh machine: `./scripts/bootstrap-machine.sh`.

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
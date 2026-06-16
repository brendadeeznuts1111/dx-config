#!/usr/bin/env bash
# Deploy dx-config into the home directory via symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
: "${HOME:?HOME is not set}"

link_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      rm -f "$dest"
    else
      mv "$dest" "${dest}.bak.$(date +%s)"
      echo "backed up $dest"
    fi
  fi
  ln -sf "$src" "$dest"
  echo "linked $dest -> $src"
}

echo "dx-config install from $REPO"

link_file "$REPO/config/dx/herdr.toml" "$HOME/.config/dx/herdr.toml"
link_file "$REPO/config/dx/herdr.json" "$HOME/.config/dx/herdr.json"
link_file "$REPO/config/dx/herdr.md" "$HOME/.config/dx/herdr.md"
link_file "$REPO/config/dx/templates/herdr.project.toml" "$HOME/.config/dx/templates/herdr.project.toml"
link_file "$REPO/config/shell/herdr.sh" "$HOME/.config/shell/herdr.sh"
link_file "$REPO/config/agents/skills/herdr/SKILL.md" "$HOME/.config/agents/skills/herdr/SKILL.md"

# Retired Phase 1 path — remove broken symlink if a prior install left one.
legacy_agents_lib="$HOME/.config/dx/lib/herdr-agents.ts"
if [[ -L "$legacy_agents_lib" ]] && [[ ! -e "$legacy_agents_lib" ]]; then
  rm -f "$legacy_agents_lib"
  echo "removed broken symlink $legacy_agents_lib"
fi
if [[ -d "$HOME/.config/dx/lib" ]] && [[ -z "$(ls -A "$HOME/.config/dx/lib" 2>/dev/null)" ]]; then
  rmdir "$HOME/.config/dx/lib" 2>/dev/null && echo "removed empty $HOME/.config/dx/lib"
fi

# Herdr CLIs + spawn stubs are authored in kimi-toolchain → ~/.local/bin via sync + install-wrappers.
KIMI_TOOLCHAIN="${KIMI_TOOLCHAIN:-$HOME/kimi-toolchain}"
if [[ -d "$KIMI_TOOLCHAIN" ]] && command -v bun >/dev/null 2>&1; then
  (cd "$KIMI_TOOLCHAIN" && bun run sync && bash scripts/install-bin-wrappers.sh)
elif [[ -x "$KIMI_TOOLCHAIN/scripts/install-bin-wrappers.sh" ]]; then
  bash "$KIMI_TOOLCHAIN/scripts/install-bin-wrappers.sh"
else
  echo "warn: kimi-toolchain not found — run: ./scripts/bootstrap-machine.sh"
fi

# dx-config helpers only (spawn stubs come from kimi-toolchain install-wrappers).
if [[ -f "$REPO/local/bin/herdr-quickref" ]]; then
  dest="$HOME/.local/bin/herdr-quickref"
  cp -f "$REPO/local/bin/herdr-quickref" "$dest"
  chmod +x "$dest"
  echo "copied $dest"
fi

# Drop install-time backups from prior full-binary copies (cosmetic).
for bak in "$HOME/.local/bin"/herdr-*.bak.*; do
  [[ -e "$bak" ]] || continue
  rm -f "$bak"
  echo "removed stale backup $(basename "$bak")"
done

mkdir -p "$HOME/.config/herdr"
if [[ ! -L "$HOME/.config/herdr/config.toml" ]]; then
  if [[ -f "$HOME/.config/herdr/config.toml" ]]; then
    mv "$HOME/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml.bak.$(date +%s)"
  fi
  ln -sf "../dx/herdr.toml" "$HOME/.config/herdr/config.toml"
  echo "linked $HOME/.config/herdr/config.toml -> ../dx/herdr.toml"
fi

for agent_home in \
  "$HOME/.grok/skills" \
  "$HOME/.codex/skills" \
  "$HOME/.claude/skills" \
  "$HOME/.kimi-code/skills" \
  "$HOME/.hermes/skills"; do
  mkdir -p "$agent_home"
  link_file "$HOME/.config/agents/skills/herdr" "$agent_home/herdr"
done

if command -v herdr >/dev/null 2>&1; then
  herdr server reload-config 2>/dev/null || true
fi

echo "done — run herdr-doctor to verify"
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
link_file "$REPO/config/dx/lib/herdr-agents.ts" "$HOME/.config/dx/lib/herdr-agents.ts"
link_file "$REPO/config/dx/templates/herdr.project.toml" "$HOME/.config/dx/templates/herdr.project.toml"
link_file "$REPO/config/shell/herdr.sh" "$HOME/.config/shell/herdr.sh"
link_file "$REPO/config/agents/skills/herdr/SKILL.md" "$HOME/.config/agents/skills/herdr/SKILL.md"

# Bin scripts use relative imports from ~/.local/bin — copy, don't symlink.
for bin in "$REPO"/local/bin/herdr-*; do
  name="$(basename "$bin")"
  dest="$HOME/.local/bin/$name"
  if [[ -L "$dest" ]]; then
    rm -f "$dest"
  fi
  cp -f "$bin" "$dest"
  chmod +x "$dest"
  echo "copied $dest"
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
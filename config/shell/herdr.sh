# Herdr — DX-integrated shell helpers
# Docs: ~/.config/dx/herdr.md  Config: ~/.config/dx/herdr.toml

: "${DX_HERDR_CONFIG:=$HOME/.config/dx/herdr.toml}"
: "${DX_HERDR_MANIFEST:=$HOME/.config/dx/herdr.json}"
export HERDR_CONFIG_PATH="$DX_HERDR_CONFIG"

unalias herder 2>/dev/null

_herder_bootstrap_if_configured() {
  local dir="${1%/}"
  shift
  [[ $# -gt 0 ]] && return 1
  [[ "$dir" == "$HOME" ]] && return 1
  command -v herdr-project >/dev/null 2>&1 || return 1
  herdr-project has-config "$dir" >/dev/null 2>&1 || return 1
  local attach_flag=()
  [[ "${HERDR_ENV:-}" != "1" ]] && attach_flag=(--attach)
  herdr-project bootstrap "$dir" "${attach_flag[@]}"
}

herder() {
  if [[ $# -ge 1 && -d "$1" ]]; then
    local dir="${1%/}"
    shift
    if _herder_bootstrap_if_configured "$dir" "$@"; then
      return $?
    fi
    (cd -- "$dir" && command herdr "$@")
  elif [[ $# -eq 0 ]] && _herder_bootstrap_if_configured "$(pwd)"; then
    return $?
  else
    command herdr "$@"
  fi
}

herder-remote() {
  command herdr --remote "$@"
}

# Named Herdr server — independent workspaces/socket; shared ~/.config/dx/herdr.toml
# https://herdr.dev/docs/persistence-remote/#named-sessions
herder-session() {
  if [[ $# -eq 0 ]]; then
    command herdr session list
    return
  fi
  command herdr session attach "$@"
}

herder-edit-config() {
  "${EDITOR:-nano}" "$DX_HERDR_CONFIG"
  command herdr server reload-config
}

herder-doctor() {
  command herdr-doctor "$@"
}

herder-maintain() {
  if command -v brew >/dev/null 2>&1; then
    brew upgrade herdr
  else
    echo "brew not found; skip herdr upgrade" >&2
  fi
  command herdr server update-agent-manifests
  command herdr server reload-config
  command herdr-doctor "$@"
}

herder-project() {
  command herdr-project "$@"
}

herder-quickref() {
  command herdr-quickref "$@"
}
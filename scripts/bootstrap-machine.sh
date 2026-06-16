#!/usr/bin/env bash
# Fresh-machine bootstrap: kimi-toolchain sync + dx-config install + verify.
set -euo pipefail

DX_REPO="$(cd "$(dirname "$0")/.." && pwd)"
KIMI_TOOLCHAIN="${KIMI_TOOLCHAIN:-$HOME/kimi-toolchain}"

: "${HOME:?HOME is not set}"

echo "bootstrap: dx-config + kimi-toolchain Herdr wiring"
echo "  dx-config:      $DX_REPO"
echo "  kimi-toolchain: $KIMI_TOOLCHAIN"
echo

if [[ ! -d "$KIMI_TOOLCHAIN" ]]; then
  echo "error: kimi-toolchain not found at $KIMI_TOOLCHAIN"
  echo "  clone: git clone git@github.com:brendadeeznuts1111/kimi-toolchain.git \"$KIMI_TOOLCHAIN\""
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun not on PATH (required for kimi-toolchain sync)"
  exit 1
fi

echo "== kimi-toolchain sync + wrappers =="
(cd "$KIMI_TOOLCHAIN" && bun run sync && bun run install-wrappers)

echo
echo "== dx-config install =="
"$DX_REPO/scripts/install.sh"

echo
if command -v herdr-doctor >/dev/null 2>&1; then
  echo "== herdr-doctor =="
  herdr-doctor || true
else
  echo "warn: herdr-doctor not on PATH — install herdr binary separately"
fi

echo
echo "bootstrap complete"
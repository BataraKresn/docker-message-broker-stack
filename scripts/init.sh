#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "[INFO] Created $(basename "$dst") from $(basename "$src")"
  fi
}

copy_if_missing "$ROOT_DIR/.env.dev.example" "$ROOT_DIR/.env.dev"
copy_if_missing "$ROOT_DIR/.env.prod.example" "$ROOT_DIR/.env.prod"

echo "[OK] Initialization complete."

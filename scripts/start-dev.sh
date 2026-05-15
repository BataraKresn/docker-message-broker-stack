#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/init.sh
./scripts/validate-env.sh dev

docker compose -f docker-compose.dev.yml --env-file .env.dev up -d

echo "[OK] Dev stack is up."

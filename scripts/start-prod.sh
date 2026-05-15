#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/init.sh
./scripts/validate-env.sh prod

docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod up -d

echo "[OK] Production stack is up with monitoring."

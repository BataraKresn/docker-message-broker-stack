#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml --env-file .env.dev down || true
docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod down || true

echo "[OK] All stacks stopped."

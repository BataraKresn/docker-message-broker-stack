#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml --env-file .env.dev down -v --remove-orphans || true
docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod down -v --remove-orphans || true

echo "[OK] Containers, networks, and volumes from compose files have been removed."

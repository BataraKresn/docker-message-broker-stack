#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dev}"
ENV_FILE=".env.${MODE}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] $ENV_FILE not found"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

SERVICE="redis"
[[ "$MODE" == "prod" ]] && SERVICE="redis-master"

docker compose -f "docker-compose.${MODE}.yml" --env-file "$ENV_FILE" exec -T "$SERVICE" redis-cli -a "$REDIS_PASSWORD" ping

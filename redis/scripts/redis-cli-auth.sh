#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dev}"
ENV_FILE=".env.${MODE}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
SERVICE="redis"
[[ "$MODE" == "prod" ]] && SERVICE="redis-master"

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec "$SERVICE" redis-cli -a "$REDIS_PASSWORD"

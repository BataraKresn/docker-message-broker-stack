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

echo "[INFO] SET/GET test"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" SET health:test "ok"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" GET health:test

echo "[INFO] LPUSH/BRPOP queue test"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" LPUSH queue:test "job-1"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" BRPOP queue:test 1

echo "[INFO] XADD/XREAD stream test"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" XADD stream:test \* event created payload sample
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  redis-cli -a "$REDIS_PASSWORD" XREAD COUNT 1 STREAMS stream:test 0

echo "[OK] Redis queue tests completed"

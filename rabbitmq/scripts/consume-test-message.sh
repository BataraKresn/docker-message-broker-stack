#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dev}"
ENV_FILE=".env.${MODE}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
SERVICE="rabbitmq"
[[ "$MODE" == "prod" ]] && SERVICE="rabbitmq-1"

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" rabbitmqadmin \
  --username "$RABBITMQ_DEFAULT_USER" \
  --password "$RABBITMQ_DEFAULT_PASS" \
  --vhost "$RABBITMQ_DEFAULT_VHOST" \
  get queue=app.queue requeue=false count=1

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" rabbitmq-diagnostics cluster_status

echo "[OK] Test consume executed"

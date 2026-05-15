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

MSG="{\"event\":\"app.created\",\"time\":\"$(date -Iseconds)\"}"

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" rabbitmqadmin \
  --username "$RABBITMQ_DEFAULT_USER" \
  --password "$RABBITMQ_DEFAULT_PASS" \
  --vhost "$RABBITMQ_DEFAULT_VHOST" \
  publish exchange=app.exchange routing_key=app.created payload="$MSG"

echo "[OK] Test message published"

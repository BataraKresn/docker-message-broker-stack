#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-prod}"
ENV_FILE=".env.${MODE}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
SERVICE="kafka"
BOOTSTRAP="kafka:9092"

if [[ "$MODE" == "prod" ]]; then
  SERVICE="kafka-1"
  BOOTSTRAP="kafka-1:9092,kafka-2:9092,kafka-3:9092"
fi

echo "event=test-$(date +%s)" | docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
  /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server "$BOOTSTRAP" --topic app-events

echo "[OK] Produced test message"

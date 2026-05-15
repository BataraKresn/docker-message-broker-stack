#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-prod}"
ENV_FILE=".env.${MODE}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
SERVICE="kafka"
RF=1
BOOTSTRAP="kafka:9092"

if [[ "$MODE" == "prod" ]]; then
  SERVICE="kafka-1"
  RF=3
  BOOTSTRAP="kafka-1:9092,kafka-2:9092,kafka-3:9092"
fi

for topic in app-events order-events notification-events audit-logs; do
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE" \
    /opt/bitnami/kafka/bin/kafka-topics.sh \
    --bootstrap-server "$BOOTSTRAP" \
    --create --if-not-exists --topic "$topic" --partitions 3 --replication-factor "$RF"
done

echo "[OK] Topics created"

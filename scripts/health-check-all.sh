#!/bin/bash
# Health check for all services in docker-message-broker-stack
set -e

COMPOSE_FILE="${1:-docker-compose.dev.yml}"
ENV_FILE="${2:-.env.dev}"

echo "=== Health Check: docker-message-broker-stack ==="
echo "Compose file: $COMPOSE_FILE"
echo "Env file: $ENV_FILE"
echo ""

# Check Redis
echo "[1/4] Checking Redis..."
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T redis redis-cli ping > /dev/null 2>&1; then
  echo "✓ Redis is healthy"
else
  echo "✗ Redis is unhealthy"
  exit 1
fi

# Check RabbitMQ
echo "[2/4] Checking RabbitMQ..."
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T rabbitmq rabbitmq-diagnostics -q ping > /dev/null 2>&1; then
  echo "✓ RabbitMQ is healthy"
else
  echo "✗ RabbitMQ is unhealthy"
  exit 1
fi

# Check Kafka
echo "[3/4] Checking Kafka..."
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T kafka /opt/bitnami/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092 > /dev/null 2>&1; then
  echo "✓ Kafka is healthy"
else
  echo "✗ Kafka is unhealthy"
  exit 1
fi

# Check containers running
echo "[4/4] Checking container status..."
RUNNING=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps -q | wc -l)
EXPECTED=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config --services | wc -l)

if [[ $RUNNING -eq $EXPECTED ]]; then
  echo "✓ All containers running ($RUNNING/$EXPECTED)"
else
  echo "✗ Not all containers running ($RUNNING/$EXPECTED)"
  exit 1
fi

echo ""
echo "=== All services are healthy ==="

#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP="kafka-1:9092,kafka-2:9092,kafka-3:9092"

for topic in app-events order-events notification-events audit-logs; do
  /opt/bitnami/kafka/bin/kafka-topics.sh \
    --bootstrap-server "$BOOTSTRAP" \
    --create --if-not-exists \
    --topic "$topic" \
    --replication-factor 3 \
    --partitions 3
done

echo "[OK] Default topics are ready"

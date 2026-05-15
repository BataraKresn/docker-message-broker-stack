#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

backup_volume() {
  local volume_name="$1"
  local output_file="$BACKUP_DIR/${volume_name}-${STAMP}.tar.gz"
  echo "[INFO] Backing up volume: $volume_name"
  docker run --rm \
    -v "${volume_name}:/data:ro" \
    -v "$BACKUP_DIR:/backup" \
    alpine:3.20 \
    sh -c "tar -czf /backup/$(basename "$output_file") -C /data ."
}

for volume in \
  redis_master_data redis_replica_data rabbitmq_1_data rabbitmq_2_data rabbitmq_3_data \
  kafka_1_data kafka_2_data kafka_3_data prometheus_data grafana_data; do
  backup_volume "$volume" || echo "[WARN] Volume $volume not found or empty."
done

echo "[OK] Backup completed in $BACKUP_DIR"

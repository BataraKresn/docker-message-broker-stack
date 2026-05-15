#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "[ERROR] Backup directory not found: $BACKUP_DIR"
  exit 1
fi

restore_volume() {
  local volume_name="$1"
  local archive_file
  archive_file="$(ls -1t "$BACKUP_DIR"/${volume_name}-*.tar.gz 2>/dev/null | head -n1 || true)"

  if [[ -z "$archive_file" ]]; then
    echo "[WARN] No backup archive found for $volume_name"
    return 0
  fi

  echo "[INFO] Restoring $volume_name from $(basename "$archive_file")"
  docker run --rm \
    -v "${volume_name}:/data" \
    -v "$BACKUP_DIR:/backup:ro" \
    alpine:3.20 \
    sh -c "rm -rf /data/* && tar -xzf /backup/$(basename "$archive_file") -C /data"
}

for volume in \
  redis_master_data redis_replica_data rabbitmq_1_data rabbitmq_2_data rabbitmq_3_data \
  kafka_1_data kafka_2_data kafka_3_data prometheus_data grafana_data; do
  restore_volume "$volume"
done

echo "[OK] Restore completed."

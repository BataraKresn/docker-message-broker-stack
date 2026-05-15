#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"
DATA_DIR="$ROOT_DIR/data"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "[ERROR] Backup directory not found: $BACKUP_DIR"
  exit 1
fi

restore_path() {
  local relative_path="$1"
  local target_path="$DATA_DIR/$relative_path"
  local backup_label="data-${relative_path//\//-}"
  local archive_file
  archive_file="$(ls -1t "$BACKUP_DIR"/${backup_label}-*.tar.gz 2>/dev/null | head -n1 || true)"

  if [[ -z "$archive_file" ]]; then
    echo "[WARN] No backup archive found for $relative_path"
    return 0
  fi

  mkdir -p "$target_path"
  echo "[INFO] Restoring $relative_path from $(basename "$archive_file")"
  rm -rf "$target_path"/*
  tar -xzf "$archive_file" -C "$target_path"
}

for relative_path in \
  dev/redis dev/redisinsight dev/rabbitmq dev/kafka \
  prod/redis-master prod/redis-replica prod/rabbitmq-1 prod/rabbitmq-2 prod/rabbitmq-3 \
  prod/kafka-1 prod/kafka-2 prod/kafka-3 \
  monitoring/prometheus monitoring/grafana; do
  restore_path "$relative_path"
done

echo "[OK] Restore completed."

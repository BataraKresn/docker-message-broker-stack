#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
DATA_DIR="$ROOT_DIR/data"

mkdir -p "$BACKUP_DIR"

backup_path() {
  local source_path="$1"
  local label="$2"
  local output_file="$BACKUP_DIR/${label}-${STAMP}.tar.gz"

  if [[ ! -d "$source_path" ]]; then
    echo "[WARN] Path tidak ditemukan: $source_path"
    return 0
  fi

  echo "[INFO] Backing up path: $source_path"
  tar -czf "$output_file" -C "$source_path" .
}

for relative_path in \
  dev/redis dev/redisinsight dev/rabbitmq dev/kafka \
  prod/redis-master prod/redis-replica prod/rabbitmq-1 prod/rabbitmq-2 prod/rabbitmq-3 \
  prod/kafka-1 prod/kafka-2 prod/kafka-3 \
  monitoring/prometheus monitoring/grafana; do
  backup_path "$DATA_DIR/$relative_path" "data-${relative_path//\//-}"
done

echo "[OK] Backup completed in $BACKUP_DIR"

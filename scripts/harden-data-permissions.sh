#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-prod}"

if [[ "$MODE" != "dev" && "$MODE" != "prod" && "$MODE" != "all" ]]; then
  echo "[ERROR] Mode tidak valid: $MODE"
  echo "Usage: $0 [dev|prod|all]"
  exit 1
fi

if [[ "${DRY_RUN:-0}" != "0" && "${DRY_RUN:-0}" != "1" ]]; then
  echo "[ERROR] DRY_RUN harus bernilai 0 atau 1"
  exit 1
fi

run_cmd() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[DRY-RUN] $*"
    return 0
  fi

  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "[ERROR] Perlu akses root atau sudo untuk mengubah owner/permission."
    exit 1
  fi
}

ensure_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      echo "[DRY-RUN] mkdir -p $path"
    else
      mkdir -p "$path"
      echo "[INFO] Created directory: $path"
    fi
  fi
}

harden_path() {
  local path="$1"
  local uid="$2"
  local gid="$3"
  local mode="$4"

  ensure_dir "$path"

  echo "[INFO] Hardening $path -> owner ${uid}:${gid}, mode ${mode}"
  run_cmd chown -R "${uid}:${gid}" "$path"
  run_cmd find "$path" -type d -exec chmod "$mode" {} +
  run_cmd find "$path" -type f -exec chmod 640 {} +
}

# UID/GID defaults (bisa dioverride via env bila image custom)
REDIS_UID="${REDIS_UID:-999}"
REDIS_GID="${REDIS_GID:-999}"
RABBITMQ_UID="${RABBITMQ_UID:-999}"
RABBITMQ_GID="${RABBITMQ_GID:-999}"
KAFKA_UID="${KAFKA_UID:-1001}"
KAFKA_GID="${KAFKA_GID:-1001}"
PROMETHEUS_UID="${PROMETHEUS_UID:-65534}"
PROMETHEUS_GID="${PROMETHEUS_GID:-65534}"
GRAFANA_UID="${GRAFANA_UID:-472}"
GRAFANA_GID="${GRAFANA_GID:-472}"
REDISINSIGHT_UID="${REDISINSIGHT_UID:-1000}"
REDISINSIGHT_GID="${REDISINSIGHT_GID:-1000}"

if [[ "$MODE" == "dev" || "$MODE" == "all" ]]; then
  echo "[INFO] Applying dev hardening profile"
  harden_path "$ROOT_DIR/data/dev/redis" "$REDIS_UID" "$REDIS_GID" 750
  harden_path "$ROOT_DIR/data/dev/rabbitmq" "$RABBITMQ_UID" "$RABBITMQ_GID" 750
  harden_path "$ROOT_DIR/data/dev/kafka" "$KAFKA_UID" "$KAFKA_GID" 750
  harden_path "$ROOT_DIR/data/dev/redisinsight" "$REDISINSIGHT_UID" "$REDISINSIGHT_GID" 750
fi

if [[ "$MODE" == "prod" || "$MODE" == "all" ]]; then
  echo "[INFO] Applying production hardening profile"
  harden_path "$ROOT_DIR/data/prod/redis-master" "$REDIS_UID" "$REDIS_GID" 750
  harden_path "$ROOT_DIR/data/prod/redis-replica" "$REDIS_UID" "$REDIS_GID" 750

  harden_path "$ROOT_DIR/data/prod/rabbitmq-1" "$RABBITMQ_UID" "$RABBITMQ_GID" 750
  harden_path "$ROOT_DIR/data/prod/rabbitmq-2" "$RABBITMQ_UID" "$RABBITMQ_GID" 750
  harden_path "$ROOT_DIR/data/prod/rabbitmq-3" "$RABBITMQ_UID" "$RABBITMQ_GID" 750

  harden_path "$ROOT_DIR/data/prod/kafka-1" "$KAFKA_UID" "$KAFKA_GID" 750
  harden_path "$ROOT_DIR/data/prod/kafka-2" "$KAFKA_UID" "$KAFKA_GID" 750
  harden_path "$ROOT_DIR/data/prod/kafka-3" "$KAFKA_UID" "$KAFKA_GID" 750

  harden_path "$ROOT_DIR/data/monitoring/prometheus" "$PROMETHEUS_UID" "$PROMETHEUS_GID" 750
  harden_path "$ROOT_DIR/data/monitoring/grafana" "$GRAFANA_UID" "$GRAFANA_GID" 750
fi

echo "[OK] Data permission hardening selesai untuk mode: $MODE"

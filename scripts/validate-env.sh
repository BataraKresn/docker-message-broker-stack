#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dev}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.${MODE}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] File $ENV_FILE tidak ditemukan."
  echo "        Jalankan ./scripts/init.sh lalu sesuaikan nilai secret."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

check_default_secret() {
  local key="$1"
  local val="$2"
  if [[ "$val" == *"change_me"* ]] || [[ "$val" == *"must_be_strong"* ]]; then
    echo "[ERROR] $key masih default. Ganti dengan password kuat."
    exit 1
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker belum terpasang."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERROR] Docker Compose plugin tidak ditemukan."
  exit 1
fi

check_default_secret "REDIS_PASSWORD" "${REDIS_PASSWORD:-}"
check_default_secret "RABBITMQ_DEFAULT_PASS" "${RABBITMQ_DEFAULT_PASS:-}"
check_default_secret "RABBITMQ_ERLANG_COOKIE" "${RABBITMQ_ERLANG_COOKIE:-}"
check_default_secret "GRAFANA_ADMIN_PASSWORD" "${GRAFANA_ADMIN_PASSWORD:-}"

ports=(6379 5672 15672 9092 8080 5540 9090 3000)
for p in "${ports[@]}"; do
  if ss -lnt "( sport = :$p )" | grep -q ":$p"; then
    echo "[WARN] Port $p sedang digunakan oleh proses lain."
  fi
done

if [[ "$MODE" == "prod" ]]; then
  mem_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
  min_kb=$((8 * 1024 * 1024))
  if [[ "${mem_kb:-0}" -lt "$min_kb" ]]; then
    echo "[ERROR] Minimal memory production disarankan >= 8GB."
    exit 1
  fi
fi

echo "[OK] Validasi environment ($MODE) selesai."

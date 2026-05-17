#!/bin/bash
# Generate strong random secrets for .env.dev and .env.prod
set -e

generate_secret() {
  openssl rand -base64 "$1"
}

update_env() {
  local env_file="$1"
  local env_type="$2"
  
  if [[ ! -f "$env_file" ]]; then
    echo "$env_file not found!"
    exit 1
  fi

  # Generate secrets
  REDIS_PASSWORD=$(generate_secret 24)
  RABBITMQ_DEFAULT_PASS=$(generate_secret 24)
  RABBITMQ_ERLANG_COOKIE=$(generate_secret 32)
  KAFKA_CLUSTER_ID=$(generate_secret 16)
  GRAFANA_ADMIN_PASSWORD=$(generate_secret 24)

  # Use shorter secrets for dev
  if [[ "$env_type" == "dev" ]]; then
    REDIS_PASSWORD=$(generate_secret 16)
    RABBITMQ_DEFAULT_PASS=$(generate_secret 16)
    RABBITMQ_ERLANG_COOKIE=$(generate_secret 16)
    KAFKA_CLUSTER_ID=$(generate_secret 12)
    GRAFANA_ADMIN_PASSWORD=$(generate_secret 16)
  fi

  # Replace values in env file
  sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" "$env_file"
  sed -i "s/^RABBITMQ_DEFAULT_PASS=.*/RABBITMQ_DEFAULT_PASS=$RABBITMQ_DEFAULT_PASS/" "$env_file"
  sed -i "s/^RABBITMQ_ERLANG_COOKIE=.*/RABBITMQ_ERLANG_COOKIE=$RABBITMQ_ERLANG_COOKIE/" "$env_file"
  sed -i "s/^KAFKA_CLUSTER_ID=.*/KAFKA_CLUSTER_ID=$KAFKA_CLUSTER_ID/" "$env_file"
  sed -i "s/^GRAFANA_ADMIN_PASSWORD=.*/GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD/" "$env_file"

  echo "Updated secrets in $env_file"
}

update_env ".env.prod" "prod"
update_env ".env.dev" "dev"

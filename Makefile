SHELL := /bin/bash

PROJECT := docker-message-broker-stack

.PHONY: dev-up dev-down dev-logs prod-up prod-down prod-logs ps redis-cli rabbitmq-status kafka-topics test-redis test-rabbitmq test-kafka backup restore clean

dev-up:
	./scripts/start-dev.sh

dev-down:
	docker compose -f docker-compose.dev.yml --env-file .env.dev down

dev-logs:
	docker compose -f docker-compose.dev.yml --env-file .env.dev logs -f --tail=200

prod-up:
	./scripts/start-prod.sh

prod-down:
	docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod down

prod-logs:
	docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod logs -f --tail=200

ps:
	docker compose -f docker-compose.dev.yml --env-file .env.dev ps || true
	docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.prod ps || true

redis-cli:
	./redis/scripts/redis-cli-auth.sh

rabbitmq-status:
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec rabbitmq-1 rabbitmq-diagnostics cluster_status

kafka-topics:
	docker compose -f docker-compose.prod.yml --env-file .env.prod exec kafka-1 /opt/bitnami/kafka/bin/kafka-topics.sh --bootstrap-server kafka-1:9092,kafka-2:9092,kafka-3:9092 --list

test-redis:
	./redis/scripts/redis-queue-test.sh

test-rabbitmq:
	./rabbitmq/scripts/create-test-message.sh && ./rabbitmq/scripts/consume-test-message.sh

test-kafka:
	./kafka/scripts/create-topics.sh && ./kafka/scripts/producer-test.sh && ./kafka/scripts/consumer-test.sh

backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh

clean:
	./scripts/clean.sh

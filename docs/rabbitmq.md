# RabbitMQ

## Development

- Single node `rabbitmq:management`
- Plugin: management + prometheus
- Definitions preload queue/exchange/binding/DLQ/retry

## Production

- Cluster 3 node (`rabbitmq-1`, `rabbitmq-2`, `rabbitmq-3`)
- Shared Erlang cookie dari env
- HAProxy untuk AMQP `:5672`
- Definitions + policy untuk queue durable dan retry/DLQ

## Verifikasi Operasional

- Cluster status:
  - `make rabbitmq-status`
- Publish/consume test:
  - `make test-rabbitmq`
- Management API internal:
  - `GET /api/queues` pada node management yang diizinkan

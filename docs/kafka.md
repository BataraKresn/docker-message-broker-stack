# Kafka (KRaft)

## Development

- Single node KRaft (tanpa ZooKeeper)
- Kafka UI (hanya dev)
- Auto topic create boleh aktif

## Production

- 3 broker/controller KRaft
- Replication factor 3
- Min ISR 2
- Auto topic create disabled
- Topic default: `app-events`, `order-events`, `notification-events`, `audit-logs`

## Catatan konfigurasi penting

- `process.roles=broker,controller`
- `controller.quorum.voters` wajib konsisten di semua broker
- `advertised.listeners` harus sesuai DNS/service name client
- Client gunakan beberapa bootstrap servers, contoh:
  - `kafka-1:9092,kafka-2:9092,kafka-3:9092`

## Test Command

- Create topics: `./kafka/scripts/create-topics.sh prod`
- List topics: `make kafka-topics`
- Produce/consume: `make test-kafka`

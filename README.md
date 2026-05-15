# docker-message-broker-stack

Template **production-ready** Docker Compose untuk stack message broker:

- **Redis** (cache, simple queue, background job)
- **RabbitMQ** (task queue, routing, retry, dead letter queue)
- **Kafka (KRaft)** (event streaming throughput tinggi)

Mendukung dua mode operasi:

1. **Development** (ringan dan cepat untuk local)
2. **Production** (lebih aman, modular, dan siap hardening)

---

## 1) Overview

Repository ini dirancang sebagai baseline infrastruktur DevOps untuk service message broker multi-pattern. Seluruh stack berbasis Docker Compose dengan struktur modular per komponen.

## 2) Kapan menggunakan Redis, RabbitMQ, Kafka

| Teknologi | Kekuatan Utama | Cocok Untuk | Catatan |
|---|---|---|---|
| Redis | Super cepat, simple | Cache, simple queue, background jobs | Tidak ideal untuk event streaming besar jangka panjang |
| RabbitMQ | Routing kuat, ACK/retry/DLQ mature | Task queue, async jobs, microservices messaging | Throughput biasanya di bawah Kafka untuk skala event streaming |
| Kafka | Throughput tinggi, event retention, consumer group | Event streaming, event pipeline, analytics ingress | Operasional lebih kompleks |

## 3) Architecture

Lihat detail di `docs/architecture.md` dan diagram di `docs/diagrams/`.

### Ringkas
- **Dev:** Redis single, RabbitMQ single + management, Kafka single KRaft + Kafka UI.
- **Prod:** Redis master/replica/sentinel, RabbitMQ 3 node + HAProxy AMQP, Kafka KRaft 3 broker/controller, monitoring Prometheus + Grafana.

## 4) Development setup

1. Inisialisasi env:
   - Copy `.env.dev.example` menjadi `.env.dev`
2. Sesuaikan password di `.env.dev`
3. Jalankan:
   - `make dev-up`

Stop stack dev:
- `make dev-down`

Log dev:
- `make dev-logs`

## 5) Production setup

1. Copy `.env.prod.example` menjadi `.env.prod`
2. Wajib ganti seluruh password default
3. Jalankan validasi:
   - `./scripts/validate-env.sh prod`
4. Start stack production + monitoring:
   - `make prod-up`

Stop stack production:
- `make prod-down`

Log production:
- `make prod-logs`

## 6) Environment variable

Gunakan:

- `.env.example` (referensi umum)
- `.env.dev.example` (template dev)
- `.env.prod.example` (template prod)

File env real (`.env.dev`, `.env.prod`) **tidak di-commit** (sudah masuk `.gitignore`).

## 7) Port mapping

### Development (public local)

- Redis: `6379`
- Redis Insight (optional profile `tools`): `5540`
- RabbitMQ AMQP: `5672`
- RabbitMQ Management: `15672`
- Kafka: `9092`
- Kafka UI: `8080`

### Production

- Hanya expose port yang diperlukan.
- Default expose eksternal: **AMQP LB** `5672`, Prometheus `9090`, Grafana `3000`.
- Redis/Kafka tidak diekspos publik secara langsung.

## 8) Security notes

- Jangan expose Redis/Kafka langsung ke internet.
- RabbitMQ management sebaiknya internal / reverse proxy + auth tambahan.
- Gunakan password kuat dari env.
- Gunakan firewall (lihat `docs/production-hardening.md`).
- Pertimbangkan TLS + Docker Secrets untuk hardening lanjutan.

## 9) Redis usage example

Script test:

- `make test-redis`

Menguji:
- `SET/GET`
- `LPUSH/BRPOP`
- `XADD/XREAD` (Redis Streams)

## 10) RabbitMQ usage example

Script test:

- `make test-rabbitmq`

Menguji:
- publish
- consume
- cluster status

## 11) Kafka usage example

Script test:

- `make test-kafka`

Menguji:
- create/list topic
- producer/consumer
- consumer group list

> Catatan penting Kafka: jangan treat Kafka seperti service HTTP yang cukup dibalik load balancer tunggal. Client sebaiknya menggunakan **multi bootstrap servers** (`kafka-1:9092,kafka-2:9092,kafka-3:9092`) dan `advertised.listeners` harus benar.

## 12) Monitoring

Compose monitoring berada di `docker-compose.monitoring.yml`:

- Prometheus
- Grafana
- Redis exporter
- RabbitMQ metrics via plugin Prometheus
- Kafka exporter

Dashboard placeholder tersedia di:
- `monitoring/grafana/dashboards/`

## 13) Backup & restore

- Backup volume: `make backup`
- Restore volume: `make restore`

Script ada di:
- `scripts/backup.sh`
- `scripts/restore.sh`

## 14) Troubleshooting

Lihat `docs/troubleshooting.md` untuk kasus:

- Redis NOAUTH
- Redis replica tidak sync
- RabbitMQ node tidak join cluster
- RabbitMQ queue stuck
- Kafka advertised.listeners salah
- Kafka broker tidak join quorum
- Kafka consumer tidak menerima message
- Port already allocated
- Permission denied volume

## 15) Production checklist

- [ ] Semua secret default sudah diganti
- [ ] Port broker privat tidak terbuka ke internet
- [ ] Firewall/UFW hanya allow app + monitoring hosts
- [ ] Monitoring aktif dan dashboard terlihat
- [ ] Backup rutin tervalidasi restore test
- [ ] Log rotation aktif (`json-file`, max-size, max-file)
- [ ] Uji failover Redis Sentinel dilakukan
- [ ] Uji cluster RabbitMQ dan quorum Kafka dilakukan

---

## Perintah Makefile cepat

- `make dev-up`
- `make dev-down`
- `make dev-logs`
- `make prod-up`
- `make prod-down`
- `make prod-logs`
- `make ps`
- `make redis-cli`
- `make rabbitmq-status`
- `make kafka-topics`
- `make test-redis`
- `make test-rabbitmq`
- `make test-kafka`
- `make backup`
- `make restore`
- `make clean`

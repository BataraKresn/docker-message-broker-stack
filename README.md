# Docker Message Broker Stack

[![CI Compose Lint](https://github.com/BataraKresn/docker-message-broker-stack/actions/workflows/ci-compose-lint.yml/badge.svg)](https://github.com/BataraKresn/docker-message-broker-stack/actions)
[![Security Scan](https://github.com/BataraKresn/docker-message-broker-stack/actions/workflows/security-scan.yml/badge.svg)](https://github.com/BataraKresn/docker-message-broker-stack/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker Compose](https://img.shields.io/badge/docker--compose-yes-blue)](https://docs.docker.com/compose/)
[![Production Ready](https://img.shields.io/badge/production--ready-yes-brightgreen)](#)
[![Language: Shell](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash)](scripts/)
[![Language: YAML](https://img.shields.io/badge/YAML-%23CB171E.svg?style=flat&logo=yaml)](docker-compose.dev.yml)

Template infrastruktur **production-ready** berbasis Docker Compose untuk tiga broker utama:

- **Redis** → cache, simple queue, background jobs
- **RabbitMQ** → task queue, routing, retry, dead-letter queue (DLQ)
- **Kafka (KRaft)** → event streaming throughput tinggi

Repository ini disiapkan sebagai baseline DevOps/SRE yang:

- rapi dan modular per komponen,
- aman untuk deployment production,
- praktis untuk local development,
- siap kolaborasi di GitHub (issue/PR template + CI lint compose).

---

## Daftar isi

1. [Overview](#overview)
2. [Kapan pakai Redis, RabbitMQ, Kafka](#kapan-pakai-redis-rabbitmq-kafka)
3. [Arsitektur](#arsitektur)
4. [Diagram Mermaid](#diagram-mermaid)
5. [Struktur repository](#struktur-repository)
6. [Prerequisites](#prerequisites)
7. [Getting Started (step-by-step)](#getting-started-step-by-step)
8. [Quick start development](#quick-start-development)
9. [Quick start production](#quick-start-production)
10. [Environment variables](#environment-variables)
11. [Port mapping](#port-mapping)
12. [Health Check](#health-check)
13. [Perintah Makefile](#perintah-makefile)
14. [Contoh penggunaan broker](#contoh-penggunaan-broker)
15. [Monitoring](#monitoring)
16. [Backup & restore](#backup--restore)
17. [Security notes](#security-notes)
18. [Troubleshooting](#troubleshooting)
19. [FAQ](#faq)
20. [Production checklist](#production-checklist)
21. [CI/CD GitHub](#cicd-github)
22. [Release notes](#release-notes)
23. [Discussion & support policy](#discussion--support-policy)

---

## Overview

Stack menyediakan dua mode:

### Development

- Redis single node + auth
- RabbitMQ single node + management UI
- Kafka single node KRaft + Kafka UI
- Port terbuka untuk debugging lokal

### Production

- Redis master + replica + sentinel
- RabbitMQ cluster 3 node + HAProxy untuk AMQP
- Kafka KRaft cluster 3 broker/controller
- Prometheus + Grafana + exporters
- Security baseline: non-public broker exposure, no-new-privileges, log rotation

> Tujuan utama: mempercepat bootstrap infrastruktur broker tanpa mengorbankan best practice operasional.

## Kapan pakai Redis, RabbitMQ, Kafka

| Teknologi | Kekuatan Utama | Cocok Untuk | Catatan |
|---|---|---|---|
| Redis | Super cepat, simple, latensi rendah | Cache, queue ringan, background jobs | Tidak ideal untuk event streaming besar jangka panjang |
| RabbitMQ | Routing kuat, ACK/retry/DLQ matang | Task queue, async job, command/event routing | Throughput umumnya di bawah Kafka untuk skala stream besar |
| Kafka | Throughput tinggi, retention, consumer group | Event streaming, data pipeline, audit/event log | Operasional lebih kompleks |

## Arsitektur

- **Compose dev:** `docker-compose.dev.yml`
- **Compose prod:** `docker-compose.prod.yml`
- **Compose monitoring:** `docker-compose.monitoring.yml`

Dokumen detail:

- `docs/architecture.md`
- `docs/capacity-planning.md`
- `docs/redis.md`
- `docs/rabbitmq.md`
- `docs/kafka.md`
- `docs/production-hardening.md`
- `docs/troubleshooting.md`

---

## Diagram Mermaid

Diagram berikut adalah versi inline yang sudah siap render di GitHub.

### 1) Full topology

```mermaid
flowchart TB
  APP[Application Layer]

  subgraph Redis
    RM[(Master)]
    RR[(Replica)]
    RS[Sentinel]
    RM --> RR
    RS --> RM
  end

  subgraph RabbitMQ
    RLB[HAProxy AMQP]
    R1[RabbitMQ-1]
    R2[RabbitMQ-2]
    R3[RabbitMQ-3]
    RLB --> R1
    RLB --> R2
    RLB --> R3
  end

  subgraph Kafka
    K1[Kafka-1]
    K2[Kafka-2]
    K3[Kafka-3]
  end

  subgraph Observability
    PROM[Prometheus]
    GRAF[Grafana]
    PROM --> GRAF
  end

  APP --> RM
  APP --> RLB
  APP --> K1
  APP --> K2
  APP --> K3
```

### 2) Message flow (Redis, RabbitMQ, Kafka)

```mermaid
flowchart LR
  subgraph Redis Queue
    RP[Producer] -->|LPUSH| RL[(redis:list)]
    RL -->|BRPOP| RW[Worker]
  end

  subgraph RabbitMQ Flow
    AP[Producer] --> EX[app.exchange]
    EX -->|app.created| Q[app.queue]
    Q --> AC[Consumer]
    Q -->|fail| DLX[app.dlx]
    DLX --> DLQ[app.dlq]
    Q --> RETRY[app.retry]
    RETRY --> EX
  end

  subgraph Kafka Flow
    KP[Producer] --> TOPIC[app-events]
    TOPIC --> CG1[Consumer Group A]
    TOPIC --> CG2[Consumer Group B]
  end
```

> Catatan Kafka penting: jangan memperlakukan Kafka seperti endpoint HTTP tunggal di belakang load balancer. Client harus memakai **multi-bootstrap servers** dan `advertised.listeners` yang benar agar broker discovery berjalan normal.

---

## Struktur repository

```text
docker-message-broker-stack/
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── docker-compose.monitoring.yml
├── redis/
├── rabbitmq/
├── kafka/
├── monitoring/
├── examples/
├── scripts/
└── docs/
```

## Prerequisites

- Docker Engine
- Docker Compose plugin (`docker compose`)
- Linux host direkomendasikan untuk production

Rekomendasi resource:

- Dev: minimal 4 GB RAM
- Prod baseline: minimal 8 GB RAM

## Getting Started (step-by-step)

### 1. Clone Repository

```bash
git clone https://github.com/BataraKresn/docker-message-broker-stack.git
cd docker-message-broker-stack
```

### 2. Initialize Environment Files

```bash
# Copy env files from examples
make init-env

# Generate strong random secrets
make generate-env-passwords
```

### 3. Validate Configuration

```bash
# Dev environment
docker compose -f docker-compose.dev.yml --env-file .env.dev config

# Prod environment
docker compose -f docker-compose.prod.yml --env-file .env.prod config
```

### 4. Start Services

**For Development:**
```bash
make dev-up
```

**For Production (with monitoring):**
```bash
make harden-data-prod  # Hardening permissions (recommended)
make prod-up
```

### 5. Verify Health

```bash
# Check all services
make health-check

# View logs
make dev-logs  # or make prod-logs
```

### 6. Run Tests

```bash
make test-redis       # Test Redis
make test-rabbitmq    # Test RabbitMQ
make test-kafka       # Test Kafka
```

## Quick start development

1. Inisialisasi env dev (sekali saja):
   - `make init-env`
2. Generate password random (opsional, aman untuk production):
   - `make generate-env-passwords`
3. Jalankan:
   - `make dev-up`

Perintah umum:

- `make dev-down`
- `make dev-logs`
- `make ps`

## Quick start production

1. Inisialisasi env prod (sekali saja):
   - `make init-env`
2. Generate password random (wajib untuk production!):
   - `make generate-env-passwords`
3. Validasi environment:
   - `./scripts/validate-env.sh prod`
4. Hardening permission folder data (disarankan sebelum start):
  - `make harden-data-prod`
5. Jalankan:
   - `make prod-up`

Perintah umum:

- `make prod-down`
- `make prod-logs`
- `make rabbitmq-status`
- `make kafka-topics`

## Environment variables

Template tersedia di:

- `.env.dev.example` → `.env.dev`
- `.env.prod.example` → `.env.prod`

Gunakan perintah `make init-env` untuk menyalin file template jika file `.env` belum ada. Setelah itu, gunakan `make generate-env-passwords` untuk mengisi secret random yang kuat.

Prinsip:

- Jangan commit `.env`, `.env.dev`, `.env.prod`
- Semua password/credential diambil dari env
- Gunakan secret kuat untuk production

## Port mapping

### Development

| Service | Port |
|---|---:|
| Redis | 6379 |
| RedisInsight (opsional) | 5540 |
| RabbitMQ AMQP | 5672 |
| RabbitMQ Management | 15672 |
| Kafka | 9092 |
| Kafka UI | 8080 |

### Production

| Service | Port | Akses |
|---|---:|---|
| RabbitMQ AMQP via HAProxy | 5672 | App servers (allow-list) |
| Prometheus | 9090 | Network ops/monitoring |
| Grafana | 3000 | Network ops/monitoring |

`Redis` dan `Kafka` tidak diekspos public secara default.

## Health Check

Gunakan script health check untuk memverifikasi semua services berjalan dengan baik:

```bash
# Development
./scripts/health-check-all.sh docker-compose.dev.yml .env.dev

# Production
./scripts/health-check-all.sh docker-compose.prod.yml .env.prod

# Atau gunakan Makefile
make health-check
```

Script ini akan memeriksa:
- Redis connectivity dan ping
- RabbitMQ cluster status
- Kafka broker availability
- Semua container berjalan

## Perintah Makefile

| Command | Kegunaan |
|---|---|
| `make init-env` | Salin .env.dev/prod dari template (jalankan pertama kali) |
| `make generate-env-passwords` | Generate strong random secrets ke .env.dev/prod |
| `make dev-up` | Start stack development |
| `make dev-down` | Stop stack development |
| `make dev-logs` | Log stack development |
| `make prod-up` | Start stack production + monitoring |
| `make prod-down` | Stop stack production + monitoring |
| `make prod-logs` | Log stack production |
| `make ps` | Cek status container |
| `make health-check` | Health check semua services (dev + prod) |
| `make pre-commit-check` | Jalankan pre-commit validation |
| `make redis-cli` | Masuk redis-cli dengan auth |
| `make rabbitmq-status` | Cek status cluster RabbitMQ |
| `make kafka-topics` | List Kafka topics |
| `make test-redis` | Uji SET/GET, queue, stream Redis |
| `make test-rabbitmq` | Uji publish/consume RabbitMQ |
| `make test-kafka` | Uji topics + producer/consumer Kafka |
| `make backup` | Backup folder bind mount `data/` |
| `make restore` | Restore folder bind mount `data/` |
| `make clean` | Bersihkan stack + volume compose |
| `make harden-data-dev` | Hardening owner/mode folder `data/dev` |
| `make harden-data-prod` | Hardening owner/mode folder `data/prod` + monitoring |
| `make harden-data-all` | Hardening semua folder `data/` |

## Contoh penggunaan broker

### Redis

- `make test-redis`
- Sample app:
  - `examples/nodejs/redis-queue/`
  - `examples/python/redis-queue/`
  - `examples/laravel/redis-queue-env.example`

### RabbitMQ

- `make test-rabbitmq`
- Sample app:
  - `examples/nodejs/rabbitmq-producer-consumer/`
  - `examples/python/rabbitmq-producer-consumer/`
  - `examples/laravel/rabbitmq-env.example`

### Kafka

- `make test-kafka`
- Default topic prod:
  - `app-events`
  - `order-events`
  - `notification-events`
  - `audit-logs`
- Sample app:
  - `examples/nodejs/kafka-producer-consumer/`
  - `examples/python/kafka-producer-consumer/`

## Monitoring

`docker-compose.monitoring.yml` mencakup:

- Prometheus
- Grafana
- Redis exporter
- RabbitMQ metrics (prometheus plugin)
- Kafka exporter

Grafana provisioning otomatis:

- datasource: `monitoring/grafana/provisioning/datasources/`
- dashboard provider: `monitoring/grafana/provisioning/dashboards/`
- dashboard file: `monitoring/grafana/dashboards/`

## Backup & restore

- `make backup`
- `make restore`

Script:

- `scripts/backup.sh`
- `scripts/restore.sh`

Best practice:

- backup terjadwal,
- restore drill berkala,
- penyimpanan backup terenkripsi.

## Security notes

- Redis/Kafka non-public exposure
- RabbitMQ management disarankan internal/reverse proxy
- Terapkan firewall allow-list
- Gunakan secret kuat dari env
- Hardening container (`no-new-privileges`, `read_only`, `tmpfs`)
- Rotasi log Docker (`json-file`, `max-size`, `max-file`)

Hardening lanjutan:

- TLS untuk Redis/RabbitMQ/Kafka
- Kafka SASL/TLS untuk deployment multi-host
- Docker secrets atau external secret manager

Hardening permission bind mount:

- Gunakan `./scripts/harden-data-permissions.sh [dev|prod|all]` atau target Makefile yang setara.
- Script akan set owner UID/GID per service (default image):
  - Redis: `999:999`
  - RabbitMQ: `999:999`
  - Kafka (Bitnami): `1001:1001`
  - Prometheus: `65534:65534`
  - Grafana: `472:472`
- Untuk image custom, UID/GID dapat dioverride via environment variable (contoh `KAFKA_UID`, `KAFKA_GID`).

## Troubleshooting

Lihat `docs/troubleshooting.md` untuk kasus:

- Redis NOAUTH
- Redis replica tidak sync
- RabbitMQ node gagal join cluster
- RabbitMQ queue stuck
- Kafka `advertised.listeners` tidak sesuai
- Kafka broker gagal join quorum
- Kafka consumer tidak menerima message
- Port conflict / already allocated
- Permission denied pada volume

## FAQ

### Q: Bagaimana cara backup dan restore data?

A: Gunakan perintah Makefile:
```bash
make backup    # Backup ke ./data/.backup-<timestamp>.tar.gz
make restore   # Restore dari backup terakhir
```
Atau jalankan script secara langsung:
```bash
./scripts/backup.sh
./scripts/restore.sh
```

### Q: Kafka image menggunakan `bitnamilegacy`, apakah aman untuk production?

A: Ya, `confluentinc/cp-kafka:7.4.0` adalah image resmi dari Confluent (creator Kafka) dan mendapat update security secara berkala. Image ini lebih stabil dan recommended untuk production dibanding Bitnami.

### Q: Bagaimana cara mengubah password Redis/RabbitMQ/Grafana?

A: Edit file `.env.dev` atau `.env.prod`, ubah nilai password, kemudian:
```bash
make dev-down
make dev-up
```
Password baru akan digunakan saat container startup.

### Q: Berapa lama retention data Kafka default?

A: Default `KAFKA_RETENTION_HOURS=24` untuk dev dan `KAFKA_RETENTION_HOURS=168` (7 hari) untuk prod. Ubah di `.env` sesuai kebutuhan.

### Q: Bagaimana cara scale RabbitMQ/Kafka ke lebih banyak node?

A: Edit `docker-compose.prod.yml`, tambah service baru (misal `rabbitmq-4`), update `RABBITMQ_CLUSTER_NODES` atau gunakan auto-discovery. Dokumentasi detail ada di `docs/production-hardening.md`.

### Q: Health check bisa dijalankan otomatis?

A: Ya! Gunakan `make health-check` atau setup Kubernetes liveness/readiness probe yang memanggil script `./scripts/health-check-all.sh`.

### Q: Bagaimana cara setup pre-commit hooks?

A: Pre-commit hooks sudah tersedia di `.githooks/pre-commit`. Untuk mengaktifkan:
```bash
git config core.hooksPath .githooks
# Atau jalankan manual
make pre-commit-check
```

### Q: Apa saja yang dicek pre-commit?

A: Pre-commit hook memvalidasi:
- Syntax shell scripts (`.sh` files)
- Konfigurasi docker-compose (dev, prod, monitoring)
- Kehadiran `.env` files (warning saja, tidak fail)

### Q: Bagaimana cara integrate stack ini dengan Kubernetes?

A: Stack ini dirancang untuk Docker Compose. Untuk Kubernetes, konversi compose ke Helm charts atau Kustomize menggunakan tools seperti `kompose`. Contoh:
```bash
kompose convert -f docker-compose.prod.yml
```

### Q: Support untuk multi-host deployment?

A: Ya, gunakan Docker Swarm atau Kubernetes. Dokumentasi detail untuk Swarm ada di `docs/architecture.md`. Untuk production multi-host, pastikan:
- Network connectivity antar node lancar
- Shared storage atau bind mounts tersedia
- Security: TLS + SASL/RBAC aktif

### Q: Bagaimana memantau performance broker?

A: Production stack include Prometheus + Grafana. Akses:
- Grafana: `http://localhost:3000` (admin / default password)
- Prometheus: `http://localhost:9090`
- Dashboard sudah pre-provisioned untuk Kafka, RabbitMQ, Redis

## Production checklist

- [ ] Semua secret default sudah diganti
- [ ] Broker private port tidak terbuka public
- [ ] Firewall/UFW allow-list aktif
- [ ] Monitoring dan dashboard tervalidasi
- [ ] Backup + restore test tervalidasi
- [ ] Docker log rotation aktif
- [ ] Failover Redis Sentinel tervalidasi
- [ ] RabbitMQ cluster status sehat
- [ ] Kafka quorum + consumer-group test lulus

## CI/CD GitHub

Sudah tersedia:

- Issue templates: `.github/ISSUE_TEMPLATE/`
- PR template: `.github/pull_request_template.md`
- CI lint compose: `.github/workflows/ci-compose-lint.yml`

CI memvalidasi konfigurasi:

- `docker-compose.dev.yml`
- `docker-compose.prod.yml`
- `docker-compose.prod.yml + docker-compose.monitoring.yml`

## Release notes

- Changelog utama: `CHANGELOG.md`
- Detail rilis awal (bilingual ID+EN): `docs/releases/v1.0.0.md`
- Template rilis berikutnya (bilingual ID+EN): `docs/releases/TEMPLATE.md`

Rekomendasi untuk maintainers:

- gunakan `CHANGELOG.md` sebagai sumber resmi perubahan,
- salin ringkasan dari `docs/releases/<version>.md` saat membuat GitHub Release,
- pertahankan format bilingual agar ramah kontribusi global.

## Stack Images

Stack ini menggunakan beberapa image Docker untuk menjalankan layanan:

- **Redis**: `redis:7.0`
- **RabbitMQ**: `rabbitmq:3.11-management`
- **Kafka**: `bitnamilegacy/kafka:4.0.0-debian-12-r10`

> **Catatan Kafka:**
> Kafka menggunakan image dari repository `bitnamilegacy` karena perubahan kebijakan Bitnami per Agustus 2025. Image ini tetap mendapatkan dukungan untuk versi lama melalui repository ini. Lihat [Bitnami Legacy Containers](https://github.com/bitnami/containers/issues/83267) untuk detail lebih lanjut.

## Discussion & support policy

- Support policy: `SUPPORT.md`
- GitHub Discussions: https://github.com/BataraKresn/docker-message-broker-stack/discussions

Alur yang direkomendasikan:

1. Pertanyaan umum / best practice → **Discussions**
2. Bug terverifikasi / feature request → **Issues**
3. Vulnerability security → jalur privat (bukan issue publik)

---

## Dokumen pendukung

- `docs/architecture.md`
- `docs/capacity-planning.md`
- `docs/redis.md`
- `docs/rabbitmq.md`
- `docs/kafka.md`
- `docs/production-hardening.md`
- `docs/troubleshooting.md`

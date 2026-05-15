# Changelog

Semua perubahan penting pada project ini didokumentasikan di file ini.

Format mengacu pada prinsip *Keep a Changelog* dan *Semantic Versioning*.

## [1.0.0] - 2026-05-15

Rilis awal stable untuk `docker-message-broker-stack`.

### Added

- Docker Compose mode **development** untuk:
  - Redis single node + auth
  - RabbitMQ single node + management UI
  - Kafka single node KRaft + Kafka UI
- Docker Compose mode **production** untuk:
  - Redis master + replica + sentinel (+ optional HAProxy)
  - RabbitMQ cluster 3 node + HAProxy AMQP
  - Kafka KRaft cluster 3 broker/controller
- Monitoring stack:
  - Prometheus
  - Grafana (provisioning datasource + dashboard)
  - Redis exporter
  - Kafka exporter
  - RabbitMQ prometheus metrics endpoint
- Script operasional:
  - start/stop/init/clean
  - validate-env
  - backup/restore
  - healthcheck & test scripts per broker
- Contoh producer/consumer:
  - Node.js
  - Python
  - Laravel env template
- Dokumentasi lengkap:
  - README profesional
  - docs arsitektur, hardening, troubleshooting
  - diagram Mermaid topology + message flow
- GitHub collaboration baseline:
  - issue templates
  - pull request template
  - CI lint docker compose

### Security

- Non-public exposure default untuk Redis/Kafka pada mode production
- Security options container (`no-new-privileges`, read-only/tmpfs untuk service tertentu)
- Log rotation via Docker `json-file`
- Secret tidak di-commit (`.env*` real file di-ignore)

### Notes

- Untuk Kafka production, gunakan multi bootstrap servers dan `advertised.listeners` yang valid.
- Load balancer bukan pengganti mekanisme broker discovery Kafka.

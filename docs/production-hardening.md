# Production Hardening

## Network & Firewall (UFW contoh)

- Allow hanya dari app servers ke broker ports internal
- Allow hanya monitoring server ke Prometheus/Grafana
- Block akses publik langsung ke Redis/Kafka ports

Contoh kebijakan:

- allow `5672/tcp` hanya dari subnet app
- allow `9090/tcp` & `3000/tcp` hanya dari subnet ops
- deny `6379/tcp`, `9092/tcp` dari internet

## Secret Management

- Jangan commit `.env.dev` / `.env.prod`
- Gunakan secret kuat (panjang, random)
- Untuk keamanan lebih tinggi gunakan **Docker secrets** / secret manager eksternal

## TLS Recommendations

- Redis TLS: optional untuk internal segment yang sensitif
- RabbitMQ TLS: aktifkan untuk AMQP jika lintas host
- Kafka TLS/SASL: disarankan untuk cluster production multi-host

## Container Security

- `no-new-privileges`
- `read_only` untuk service yang memungkinkan
- `tmpfs` untuk write temporary path
- log rotation driver `json-file` dengan batas ukuran file

## Backup & DR

- Gunakan script `scripts/backup.sh` secara terjadwal
- Uji `scripts/restore.sh` berkala (drill)
- Simpan backup di storage terenkripsi

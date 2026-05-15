# Troubleshooting

## Redis NOAUTH Authentication required

- Pastikan client kirim password benar
- Cek `REDIS_PASSWORD` di `.env.dev/.env.prod`

## Redis replica tidak sync

- Cek `replicaof redis-master 6379`
- Cek `masterauth` sama dengan password master
- Cek network `broker_prod_net`

## RabbitMQ node tidak join cluster

- Pastikan `RABBITMQ_ERLANG_COOKIE` sama di semua node
- Cek DNS hostname service (`rabbitmq-1`, dst.)
- Jalankan `rabbitmq-diagnostics cluster_status`

## RabbitMQ queue stuck

- Cek unacked messages
- Cek consumer online
- Cek policy TTL / DLQ binding

## Kafka advertised.listeners salah

- Ciri: producer/consumer connect ke bootstrap tapi gagal fetch metadata broker lain
- Solusi: set `KAFKA_CFG_ADVERTISED_LISTENERS` sesuai nama host yang bisa di-resolve client

## Kafka broker tidak join quorum

- Cek konsistensi `controller.quorum.voters`
- Cek `node.id` unik
- Cek `KAFKA_CLUSTER_ID` sama pada semua broker

## Kafka consumer tidak menerima message

- Cek topic benar
- Cek offset (`earliest/latest`)
- Cek group.id dan lag

## Port already allocated

- Cari proses yang pakai port: `ss -lntp`
- Ubah mapping port di compose jika diperlukan

## Permission denied volume

- Cek ownership path/volume di host
- Cek policy security host (SELinux/AppArmor)

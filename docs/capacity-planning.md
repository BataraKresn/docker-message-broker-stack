# Capacity Planning

Dokumen ini membantu menentukan kapasitas infrastruktur untuk menjalankan stack broker:

- Redis
- RabbitMQ
- Kafka (KRaft)

serta keputusan **scale up** vs **scale out** berdasarkan gejala operasional.

---

## Asumsi dasar

Panduan ini adalah baseline. Hasil final tetap harus divalidasi dengan load test pada traffic aktual.

Variabel yang paling memengaruhi kapasitas:

- message throughput (msg/detik)
- ukuran pesan rata-rata (bytes)
- jumlah partisi Kafka
- jumlah consumer group
- retention policy
- durability requirement (replication, ISR)

---

## Sizing matrix (Small / Medium / Large)

> Konteks matrix: 3 broker berjalan bersama (Redis + RabbitMQ + Kafka) dalam satu environment produksi.

| Tier | Throughput indikatif | CPU | RAM | Storage (NVMe SSD) | Network | Cocok untuk |
|---|---:|---:|---:|---:|---:|---|
| Small | hingga ~5K msg/s total | 8 vCPU | 16 GB | 300–500 GB | 1 Gbps | POC, staging, production kecil non-kritikal |
| Medium | ~5K–25K msg/s total | 16 vCPU | 32 GB | 800 GB–1.5 TB | 1–10 Gbps | Production menengah, microservices aktif |
| Large | >25K msg/s total | 24–32 vCPU | 64–128 GB | 2–4 TB | 10 Gbps | Throughput tinggi, multi consumer-group, retention panjang |

### Distribusi resource per komponen (rule of thumb)

Pada tier **Medium** (16 vCPU / 32 GB):

- Kafka: ~50–60% CPU, ~50% RAM, porsi disk terbesar
- RabbitMQ: ~25–30% CPU, ~25–30% RAM
- Redis: ~10–15% CPU, ~10–15% RAM
- Monitoring + OS overhead: ~10%

> Jika Kafka retention panjang + consumer group banyak, prioritaskan disk IOPS dan RAM page cache.

---

## Rumus kapasitas retention Kafka

Gunakan estimasi sederhana berikut.

### 1) Data masuk per hari

$$
\text{ingest\_bytes\_per\_day} = \text{msg\_per\_sec} \times \text{avg\_msg\_bytes} \times 86400
$$

### 2) Total storage retention (tanpa overhead)

$$
\text{retention\_bytes} = \text{ingest\_bytes\_per\_day} \times \text{retention\_days}
$$

### 3) Koreksi replication factor

$$
\text{cluster\_bytes} = \text{retention\_bytes} \times \text{replication\_factor}
$$

### 4) Tambahkan headroom (disarankan 30%–50%)

$$
\text{required\_bytes} = \text{cluster\_bytes} \times (1 + \text{headroom})
$$

### 5) Estimasi per broker

$$
\text{per\_broker\_bytes} = \frac{\text{required\_bytes}}{\text{jumlah\_broker}}
$$

### Contoh cepat

Misal:

- 8.000 msg/s
- ukuran pesan rata-rata 1 KB (1024 bytes)
- retention 7 hari
- replication factor = 3
- headroom 40% (0.4)
- broker = 3

Perhitungan ringkas:

- ingest/day = $8000 \times 1024 \times 86400 \approx 707\ \text{GB/hari}$
- retention 7 hari = $\approx 4.95\ \text{TB}$
- kali RF 3 = $\approx 14.85\ \text{TB}$
- headroom 40% = $\approx 20.79\ \text{TB}$ total cluster
- per broker = $\approx 6.93\ \text{TB/broker}$

Artinya, untuk workload contoh ini, disk 2–4 TB/broker tidak cukup; perlu menurunkan retention, kompresi/size message, atau menambah broker/storage.

---

## Kapan scale up vs scale out

### Scale up (vertical) jika

- CPU sering > 75% tetapi jumlah node masih sedikit
- RAM pressure tinggi namun topologi masih sederhana
- bottleneck berasal dari resource lokal (CPU/RAM single node)
- Anda butuh respon cepat tanpa perubahan arsitektur besar

### Scale out (horizontal) jika

- throughput meningkat konsisten dan mendekati batas cluster
- butuh high availability/fault isolation lebih baik
- partisi Kafka perlu ditambah untuk paralelisme
- antrean RabbitMQ meningkat karena satu node jadi hotspot
- Redis membutuhkan pemisahan workload/role (cache vs queue) atau sharding

---

## Checklist keputusan scale

Gunakan checklist ini sebelum menambah kapasitas:

### A. Validasi bottleneck

- [ ] CPU, RAM, disk IOPS, network throughput sudah dimonitor per service
- [ ] P95/P99 latency producer dan consumer sudah dicatat
- [ ] Backlog queue / consumer lag diukur secara periodik

### B. Jika pilih scale up

- [ ] Sudah dipastikan bottleneck node-local, bukan desain partisi/consumer
- [ ] Host target punya ruang upgrade CPU/RAM/disk
- [ ] Dampak downtime/maintenance window dipertimbangkan

### C. Jika pilih scale out

- [ ] Kafka: rencana partisi + rebalance consumer group disiapkan
- [ ] RabbitMQ: kebijakan queue (quorum/durable/ttl/dlq) tetap konsisten
- [ ] Redis: strategi role separation/sentinel/sharding ditentukan
- [ ] Monitoring dan alerting disesuaikan untuk node tambahan

### D. Safety checks

- [ ] Backup + restore drill lulus sebelum perubahan kapasitas
- [ ] Runbook rollback tersedia
- [ ] Uji beban ulang setelah scaling selesai

---

## Rekomendasi praktis per kondisi

### Kondisi 1 — Traffic burst pendek, latency sensitif

- Prioritas: Redis + scale up memori/CPU lebih dulu

### Kondisi 2 — Task orchestration kompleks (retry/DLQ tinggi)

- Prioritas: RabbitMQ tuning + scale out node consumer

### Kondisi 3 — Event pipeline besar, retention lama, banyak consumer group

- Prioritas: Kafka scale out (broker + partisi), lalu disk/network uplift

---

## Catatan implementasi untuk repository ini

- `docker-compose.prod.yml` cocok sebagai baseline production awal.
- Untuk beban menengah-tinggi, disarankan pemisahan cluster per broker di host terpisah.
- Gunakan dokumen ini bersama:
  - `docs/architecture.md`
  - `docs/production-hardening.md`
  - `docs/troubleshooting.md`

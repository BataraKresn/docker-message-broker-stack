# Arsitektur Stack Message Broker

Dokumen ini menjelaskan topologi development dan production.

## Topologi Full Stack

```mermaid
flowchart LR
  APP[Application Services] --> REDIS[(Redis)]
  APP --> RMQLB[HAProxy AMQP LB]
  RMQLB --> RMQ1[RabbitMQ-1]
  RMQLB --> RMQ2[RabbitMQ-2]
  RMQLB --> RMQ3[RabbitMQ-3]
  APP --> K1[Kafka-1]
  APP --> K2[Kafka-2]
  APP --> K3[Kafka-3]

  RS[Redis Sentinel] --> REDIS
  REDISR[Redis Replica] --> REDIS

  PROM[Prometheus] --> REXP[Redis Exporter]
  PROM --> KEXP[Kafka Exporter]
  PROM --> RMQ1
  PROM --> RMQ2
  PROM --> RMQ3
  GRAF[Grafana] --> PROM

  classDef broker fill:#E8F1FF,stroke:#2B6CB0,stroke-width:1px,color:#1A365D;
  classDef obs fill:#E6FFFA,stroke:#2C7A7B,stroke-width:1px,color:#234E52;
  class REDIS,REDISR,RMQ1,RMQ2,RMQ3,K1,K2,K3 broker;
  class PROM,GRAF,REXP,KEXP obs;
```

## Message Flow

```mermaid
flowchart TD
  subgraph RedisQueue
    RP[Producer] -->|LPUSH| RQ[(Redis List)]
    RQ -->|BRPOP| RC[Worker]
  end

  subgraph RabbitFlow
    MP[Producer] --> EX[app.exchange]
    EX -->|app.created| Q1[app.queue]
    Q1 --> C1[Consumer]
    Q1 -->|failed| DLX[app.dlx]
    DLX --> DLQ[app.dlq]
    Q1 --> RETRY[app.retry]
    RETRY --> EX
  end

  subgraph KafkaFlow
    KP[Producer] --> TOPIC[Topic: app-events]
    TOPIC --> CG1[Consumer Group A]
    TOPIC --> CG2[Consumer Group B]
  end
```

## Catatan Kafka dan Load Balancer

Kafka **bukan** HTTP service biasa. Load balancer (jika ada) hanya untuk kebutuhan bootstrap/internal terbatas. Konfigurasi utama tetap:

- `bootstrap.servers` berisi beberapa broker
- `advertised.listeners` benar dan bisa di-resolve oleh client

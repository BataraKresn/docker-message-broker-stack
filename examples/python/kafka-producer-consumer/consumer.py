import os
from kafka import KafkaConsumer

brokers = os.getenv("KAFKA_BROKERS", "localhost:9092").split(",")
consumer = KafkaConsumer(
    "app-events",
    bootstrap_servers=brokers,
    group_id="python-group-1",
    auto_offset_reset="earliest",
)

print("[consumer] waiting...")
for msg in consumer:
    print("[consumer] got", msg.value.decode())
    break

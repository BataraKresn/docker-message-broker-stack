import json
import os
import time
from kafka import KafkaProducer

brokers = os.getenv("KAFKA_BROKERS", "localhost:9092").split(",")
producer = KafkaProducer(bootstrap_servers=brokers, value_serializer=lambda v: json.dumps(v).encode("utf-8"))
producer.send("app-events", {"id": int(time.time()), "event": "python.produced"})
producer.flush()
print("[producer] sent")

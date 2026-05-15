import json
import time
import pika
import os

url = os.getenv("RABBITMQ_URL", "amqp://admin:change_me@localhost:5672/app")
params = pika.URLParameters(url)
conn = pika.BlockingConnection(params)
ch = conn.channel()

ch.exchange_declare(exchange="app.exchange", exchange_type="topic", durable=True)
ch.basic_publish(exchange="app.exchange", routing_key="app.created", body=json.dumps({"id": int(time.time())}))
print("[producer] published")
conn.close()

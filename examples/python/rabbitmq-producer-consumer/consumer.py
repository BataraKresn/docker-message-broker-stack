import os
import pika

url = os.getenv("RABBITMQ_URL", "amqp://admin:change_me@localhost:5672/app")
params = pika.URLParameters(url)
conn = pika.BlockingConnection(params)
ch = conn.channel()

ch.queue_declare(queue="app.queue", durable=True)
ch.queue_bind(queue="app.queue", exchange="app.exchange", routing_key="app.created")

print("[consumer] waiting...")
for method, props, body in ch.consume("app.queue", inactivity_timeout=120):
    if body:
        print("[consumer] got", body.decode())
        ch.basic_ack(method.delivery_tag)
        break
conn.close()

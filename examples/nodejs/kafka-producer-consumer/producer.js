import { Kafka } from 'kafkajs';

const brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const kafka = new Kafka({ clientId: 'node-producer', brokers });
const producer = kafka.producer();

await producer.connect();
await producer.send({ topic: 'app-events', messages: [{ value: JSON.stringify({ id: Date.now(), event: 'node.produced' }) }] });
console.log('[producer] kafka message sent');
await producer.disconnect();

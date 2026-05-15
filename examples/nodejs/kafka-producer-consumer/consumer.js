import { Kafka } from 'kafkajs';

const brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const kafka = new Kafka({ clientId: 'node-consumer', brokers });
const consumer = kafka.consumer({ groupId: 'node-group-1' });

await consumer.connect();
await consumer.subscribe({ topic: 'app-events', fromBeginning: true });

await consumer.run({ eachMessage: async ({ message }) => console.log('[consumer] got', message.value?.toString()) });

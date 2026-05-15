import amqp from 'amqplib';

const url = process.env.RABBITMQ_URL || 'amqp://admin:change_me@localhost:5672/app';
const conn = await amqp.connect(url);
const ch = await conn.createChannel();

await ch.assertExchange('app.exchange', 'topic', { durable: true });
ch.publish('app.exchange', 'app.created', Buffer.from(JSON.stringify({ id: Date.now(), event: 'created' })));
console.log('[producer] message published');

await ch.close();
await conn.close();

import amqp from 'amqplib';

const url = process.env.RABBITMQ_URL || 'amqp://admin:change_me@localhost:5672/app';
const conn = await amqp.connect(url);
const ch = await conn.createChannel();

await ch.assertQueue('app.queue', { durable: true });
await ch.bindQueue('app.queue', 'app.exchange', 'app.created');
console.log('[consumer] waiting ...');

ch.consume('app.queue', (msg) => {
  if (!msg) return;
  console.log('[consumer] got', msg.content.toString());
  ch.ack(msg);
});

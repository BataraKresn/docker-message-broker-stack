import Redis from 'ioredis';

const redis = new Redis({ host: process.env.REDIS_HOST || 'localhost', port: 6379, password: process.env.REDIS_PASSWORD || 'change_me' });
const queue = process.env.REDIS_QUEUE || 'jobs:email';

await redis.lpush(queue, JSON.stringify({ id: Date.now(), type: 'email', to: 'user@example.com' }));
console.log('[producer] job pushed');
await redis.quit();

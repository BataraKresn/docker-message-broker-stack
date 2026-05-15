import Redis from 'ioredis';

const redis = new Redis({ host: process.env.REDIS_HOST || 'localhost', port: 6379, password: process.env.REDIS_PASSWORD || 'change_me' });
const queue = process.env.REDIS_QUEUE || 'jobs:email';

console.log('[worker] waiting job...');
const data = await redis.brpop(queue, 0);
console.log('[worker] got:', data?.[1]);
await redis.quit();

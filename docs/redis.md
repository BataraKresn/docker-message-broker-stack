# Redis

## Mode Development

- Single Redis
- `requirepass` aktif
- `appendonly yes`
- Healthcheck via `redis-cli -a <password> ping`

## Mode Production

- `redis-master`
- `redis-replica`
- `redis-sentinel`
- Optional `redis-lb` (HAProxy)

## Failover Test (Sentinel)

1. Jalankan stack prod
2. Cek sentinel:
   - `docker compose -f docker-compose.prod.yml --env-file .env.prod exec redis-sentinel redis-cli -p 26379 SENTINEL masters`
3. Stop master:
   - `docker compose -f docker-compose.prod.yml --env-file .env.prod stop redis-master`
4. Tunggu failover, lalu cek master baru

## Test Command

- `SET/GET`: `make test-redis`
- Queue: `LPUSH/BRPOP` via `make test-redis`
- Stream: `XADD/XREAD` via `make test-redis`

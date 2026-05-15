import os
import redis

r = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=6379,
    password=os.getenv("REDIS_PASSWORD", "change_me"),
    decode_responses=True,
)

print("[worker] waiting...")
item = r.brpop("jobs:email", timeout=0)
print("[worker] got", item)

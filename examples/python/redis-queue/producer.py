import json
import os
import time
import redis

r = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=6379,
    password=os.getenv("REDIS_PASSWORD", "change_me"),
    decode_responses=True,
)

r.lpush("jobs:email", json.dumps({"id": int(time.time()), "type": "email"}))
print("[producer] pushed")

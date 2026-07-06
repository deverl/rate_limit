# Should rate limit
# 4 cases
#   1: key not in cache (create new entry, count = 1, return false)
#   2: key in cache, not expired, count < max (increment count, return false)
#   3. key in cache, not expired, count >= max (return true)
#   4. key in cache, expired (create new entry, count = 1, return false)

import time

class Entry():
    def __init__(self, endTime:float, count:int):
        self.endTime = endTime
        self.count = count

cache = {}

# Sweep expired entries every Nth rateLimit call so stale keys
# don't accumulate forever.
EVICT_EVERY = 100
callCount = 0

def monotonicTime() -> float:
    # Unlike time.time(), time.monotonic() is not affected by system
    # clock adjustments, and it has sub-second precision.
    return time.monotonic()

def evictExpired():
    t = monotonicTime()
    expired = [key for key, e in cache.items() if t >= e.endTime]
    for key in expired:
        del cache[key]

def rateLimit(key:str, interval:int, maxCount:int) -> bool:
    global callCount
    callCount += 1
    if callCount % EVICT_EVERY == 0:
        evictExpired()

    t = monotonicTime()
    e = cache.get(key)
    if e is None:
        # Case 1
        cache[key] = Entry(t + interval, 1)
        return False

    if t >= e.endTime:
        # Case 4
        e.endTime = t + interval
        e.count = 1
        return False

    if e.count >= maxCount:
        # Case 3
        return True

    # Case 2
    e.count += 1
    return False

def main():
    # False
    print(rateLimit("device", 5, 3))
    print(rateLimit("device", 5, 3))
    print(rateLimit("device", 5, 3))

    # True
    print(rateLimit("device", 5, 3))

if __name__ == "__main__":
    main()

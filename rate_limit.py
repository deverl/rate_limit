# Should rate limit
# 4 cases
#   1: key not in cache (create new entry, count = 1, return false)
#   2: key in cache, not expired, count < max (increment count, return false)
#   3. key in cache, not expired, count >= max (increment count, return true)
#   4. key in cache, expired (create new entry, count = 1, return false)


import datetime


class Entry():
    def __init__(self, endTime:int, count:int):
        self.endTime = endTime
        self.count = count


cache = {}

def unixTime() -> int:
    return int(datetime.datetime.now().timestamp())


def rateLimit(key:str, interval:int, maxCount:int) -> bool:
    t = unixTime()
    try:
        e = cache[key]
        if t >= e.endTime:
            # Case 4
            e.endTime = t + interval
            e.count = 1
            cache[key] = e
            return False
        if e.count >= maxCount:
            # Case 3
            return True
        else:
            # Case 2
            e.count += 1
            cache[key] = e
            return False
    except:
        # Case 1
        e = Entry(t + interval, 1)
        cache[key] = e
        return False


def main():
    # False
    print(rateLimit("device", 5, 3))
    print(rateLimit("device", 5, 3))
    print(rateLimit("device", 5, 3))

    # True
    print(rateLimit("device", 5, 3))


main()


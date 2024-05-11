// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (return true)
//   4. key in cache, expired (create new entry, count = 1, return false)


cache = {};

function unixTime() {
    return Math.floor(Date.now() / 1000);
}

function rateLimit(key, interval, maxCount) {
    const t = unixTime;
    let e = cache[key];
    if (!e) {
        // Case 1
        cache[key] = { endTime: t + interval, count: 1 };
        return false;
    }
    if (t < e.endTime) {
        // Not expired.
        if (e.count < maxCount) {
            // Case 2
            e.count += 1;
            cache[key] = e;
            return false;
        }

        // Case 3
        return true;
    }

    e.endTime = t + interval;
    e.count = 1;
    cache[key] = e;
    return false;
}
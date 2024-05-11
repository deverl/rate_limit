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
        // No cached entry for the key.
        // Case 1
        cache[key] = { endTime: t + interval, count: 1 };
        return false;
    }

    // There was a cached entry for the key.
    if (t < e.endTime) {
        // Not expired.
        if (e.count < maxCount) {
            // Not expired and the count has not reached the max.
            // Case 2
            e.count += 1;
            cache[key] = e;
            return false;
        }

        // Not expired but the count has reached the max.
        // Case 3
        return true;
    }

    // Cached entry that has expired.
    // Case 4
    e.endTime = t + interval;
    e.count = 1;
    cache[key] = e;
    return false;
}


function runTest(key, interval, maxCount) {
    // false
    console.log(`rateLimit(${key}, ${interval}, ${maxCount}) => ${rateLimit(key, interval, maxCount)}`);
    console.log(`rateLimit(${key}, ${interval}, ${maxCount}) => ${rateLimit(key, interval, maxCount)}`);
    console.log(`rateLimit(${key}, ${interval}, ${maxCount}) => ${rateLimit(key, interval, maxCount)}`);

    // true
    console.log(`rateLimit(${key}, ${interval}, ${maxCount}) => ${rateLimit(key, interval, maxCount)}`);
}   



runTest('129.227.14.58:/api/v1/users', 10, 3);
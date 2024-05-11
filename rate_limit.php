<?php

// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (return true)
//   4. key in cache, expired (create new entry, count = 1, return false)



$cache = [];


function rateLimit(string $key, int $interval, int $maxCount) : bool {
    global $cache;
    $t = time();
    if (array_key_exists($key, $cache) === false) {
        // Not in cache.
        // Case 1
        $entry = ['count' => 1, 'end_time' => $t + $interval];
        $cache[$key] = $entry;
        return false;
    }

    // Entry in cache.
    $entry = $cache[$key];

    if ($t < $entry['end_time']) {
        // Entry not expired.

        if ($entry['count'] < $maxCount) {
            // In cache, not expired, and count is less than maxCount
            // Case 2
            $entry['count']++;
            $cache[$key] = $entry;
            return false;
        }    

        // In cache, not expired, count >= maxCount
        // Case 3
        return true;
    }

    // Cached entry expired.
    // Case 4
    $entry = ['count' => 1, 'end_time' => $t + $interval];
    $cache[$key] = $entry;
    return false;
}


function boolString(mixed $value) : string {
    return $value ? 'true' : 'false';
}

function runTests(string $key, int $interval, int $maxCount) {
    // false
    echo boolString(rateLimit($key, $interval, $maxCount)) . PHP_EOL;
    echo boolString(rateLimit($key, $interval, $maxCount)) . PHP_EOL;
    echo boolString(rateLimit($key, $interval, $maxCount)) . PHP_EOL;

    // true
    echo boolString(rateLimit($key, $interval, $maxCount)) . PHP_EOL;
}



runTests('sample_key', 5, 3);
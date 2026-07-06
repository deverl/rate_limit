import cache.Cache
import cache.CacheEntry

var cache = Cache()

// Sweep expired entries every Nth rateLimit call so stale keys
// don't accumulate forever.
const val EVICT_EVERY = 100
var callCount = 0L


// interval is in seconds, matching the other implementations.
fun rateLimit(key: String, interval: Int, maxCount: Int): Boolean {
    callCount++
    if (callCount % EVICT_EVERY == 0L) {
        cache.evictExpired()
    }

    var entry: CacheEntry? = cache.get(key)
    if (entry != null) {
        if (entry.value < maxCount) {
            entry.value++
            cache.set(key, entry.value)
            return false
        } else {
            return true
        }
    } else {
        cache.set(key, 1L, interval.toLong() * 1000)
        return false
    }
}

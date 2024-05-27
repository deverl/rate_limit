
import cache.*;

var cache = Cache()

fun rateLimit(key: String, interval: Int, maxCount: Int) : Boolean {
    var entry: CacheEntry? = cache.get(key)
    if (entry != null) {
        if(entry.value < maxCount) {
            entry.value++
            cache.set(key, entry.value)
            return false;
        }
        else {
            return true
        }
    }
    else {
        cache.set(key, 1L, interval.toLong())
        return false
    }
}
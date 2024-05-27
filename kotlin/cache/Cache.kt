package cache

class Cache {
    private val cache: HashMap<String, CacheEntry>

    init {
        cache = hashMapOf()
    }

    fun set(key: String, value: Long, TTLms: Long = 0) {
        if (cache.containsKey(key)) {
            var entry = cache.get(key)
            entry!!.setValue(value, TTLms)
            cache.set(key, entry)
        } else {
            var entry = CacheEntry(value, TTLms)
            cache.set(key, entry)
        }
    }

    fun get(key: String): CacheEntry? {
        if (cache.containsKey(key)) {
            var entry = cache.get(key)
            if (!entry!!.hasExpired()) {
                return entry
            } else {
                // Expired
                println("LOG: entry with key=$key has expired")
                return null
            }
        } else {
            // Not in the cache
            return null
        }
    }
}

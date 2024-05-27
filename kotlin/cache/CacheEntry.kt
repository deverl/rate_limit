package cache

class CacheEntry(var value: Long, var TTLms: Long = 5000L) {
    private var endTime: Long? = null
    private var TTL: Long? = null

    fun hasExpired(): Boolean {
        val now = System.currentTimeMillis()
        val expired: Boolean = now >= this.endTime!!
        return expired
    }

    init {
        this.setTTL(TTLms)
    }

    fun setTTL(TTLms: Long): CacheEntry {
        val now: Long = System.currentTimeMillis()
        this.endTime = now + TTLms
        return this
    }

    fun setValue(value: Long, TTLms: Long = 0): CacheEntry {
        this.value = value
        if (TTLms > 0) {
            return this.setTTL(TTLms)
        }
        return this
    }
}

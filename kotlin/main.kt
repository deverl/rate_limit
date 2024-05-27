fun main(args: Array<String>) {
    val url = "http://ds6.us"
    val interval = 5_000
    val maxCount = 3

    // false
    println(rateLimit(url, interval, maxCount))
    println(rateLimit(url, interval, maxCount))
    println(rateLimit(url, interval, maxCount))

    // true
    println(rateLimit(url, interval, maxCount))
}


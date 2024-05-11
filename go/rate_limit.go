package main

// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (increment count, return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

//  case   cached    expired    count < max    count >= max   actions
//  ----   ------    -------    -----------    ------------   -----------------------------------------
//  1      no        --           --             --           create new entry, count = 1, return false
//  2      yes       no           yes            no           increment count, return false
//  3      yes       no           no             yes          increment count, return true
//  4      yes       yes          --             --           create new entry, count = 1, return false

import (
	"fmt"
	"os"
	"time"
)

type entry struct {
	endTime int // Window end time
	counter int // Counter
}

var cache map[string]entry

func main() {
	cache = make(map[string]entry)

	if len(os.Args) == 2 && os.Args[1] == "test" {
		key := "216.239.34.21:/api/v1/payroll_report"
		exerciseRateLimiter(key, 5, 2, 120)
		fmt.Println("")
	} else {
		key := "192.168.4.127:/api/v1/users"
		// false
		fmt.Println(rateLimit(key, 5, 3))
		fmt.Println(rateLimit(key, 5, 3))
		fmt.Println(rateLimit(key, 5, 3))

		// true
		fmt.Println(rateLimit(key, 5, 3))
	}
}

func exerciseRateLimiter(key string, count int, interval int, maxCount int) {
	for i := 0; i < count; i++ {
		for {
			shouldLimit := rateLimit(key, interval, maxCount)
			if shouldLimit {
				// Rate limited
				fmt.Println("")
				if i < count-1 {
					for {
						time.Sleep(5 * time.Millisecond)
						shouldLimit = rateLimit(key, interval, maxCount)
						if !shouldLimit {
							fmt.Print(".")
							break
						}
					}
				}
				break
			} else {
				// Not rate limited.
				fmt.Print(".")
			}
		}
	}
}

func rateLimit(key string, interval int, maxCount int) bool {
	t := int(time.Now().Unix())
	e, ok := cache[key]

	if !ok {
		// Case 1
		cache[key] = entry{endTime: t + interval, counter: 1}
		return false
	}

	if t < e.endTime {
		// Not expired.
		if e.counter < maxCount {
			// Case 2
			e.counter++
			cache[key] = e
			return false
		}

		// Case 3
		return true
	}

	// Case 4
	e.endTime = t + interval
	e.counter = 1
	cache[key] = e
	return false
}

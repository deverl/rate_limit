package main

// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (increment count, return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

import (
	"fmt"
	"time"
)

type entry struct {
	endTime int // Window end time
	counter int // Counter
}

var cache map[string]entry

func main() {
	cache = make(map[string]entry)

	exercise(5, 2, 120)

	fmt.Println("")
}

func exercise(count int, interval int, maxCount int) {
	for i := 0; i < count; i++ {
		for {
			fmt.Print(".")
			shouldLimit := rateLimit("device_info", interval, maxCount)
			// fmt.Println("shouldLimit:", shouldLimit)
			if shouldLimit {
				fmt.Println("")
				if i < count-1 {
					for {
						time.Sleep(2 * time.Millisecond)
						shouldLimit = rateLimit("device_info", interval, maxCount)
						if !shouldLimit {
							fmt.Print(".")
							break
						}
					}
				}
				break
			}
		}
	}
}

func rateLimit(key string, interval int, maxCount int) bool {
	t := int(time.Now().Unix())
	e, ok := cache[key]
	if ok {
		// Key in cache
		if t >= e.endTime {
			// Case 4
			cache[key] = entry{endTime: t + interval, counter: 1}
			return false
		} else {
			if e.counter >= maxCount {
				// Case 3
				return true
			} else {
				// Case 2
				e.counter++
				cache[key] = e
				return false
			}
		}
	} else {
		// Case 1
		cache[key] = entry{endTime: t + interval, counter: 1}
		return false
	}
}

// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3: key in cache, not expired, count >= max (return true)
//   4: key in cache, expired (create new entry, count = 1, return false)
//
//  case   cached    expired    count < max    count >= max   actions
//  ----   ------    -------    -----------    ------------   -----------------------------------------
//  1      no        --           --             --           create new entry, count = 1, return false
//  2      yes       no           yes            no           increment count, return false
//  3      yes       no           no             yes          return true
//  4      yes       yes          --             --           create new entry, count = 1, return false

use std::collections::HashMap;
use std::io::Write;
use std::time::{Duration, Instant};

struct Entry {
    end_time: Instant, // Window end time
    count: u32,        // Requests seen in the current window
}

/// Fixed-window rate limiter: at most `max_count` requests per key
/// within each `interval`-long window.
struct RateLimiter {
    interval: Duration,
    max_count: u32,
    cache: HashMap<String, Entry>,
    call_count: u64,
}

/// Sweep expired entries every Nth call so stale keys
/// don't accumulate forever.
const EVICT_EVERY: u64 = 100;

impl RateLimiter {
    fn new(interval: Duration, max_count: u32) -> Self {
        Self {
            interval,
            max_count,
            cache: HashMap::new(),
            call_count: 0,
        }
    }

    fn evict_expired(&mut self) {
        let now = Instant::now();
        self.cache.retain(|_, entry| now < entry.end_time);
    }

    /// Returns true if the request for `key` should be rate limited.
    fn should_rate_limit(&mut self, key: &str) -> bool {
        self.call_count += 1;
        if self.call_count % EVICT_EVERY == 0 {
            self.evict_expired();
        }

        let now = Instant::now();

        match self.cache.get_mut(key) {
            None => {
                // Case 1
                self.cache.insert(
                    key.to_string(),
                    Entry {
                        end_time: now + self.interval,
                        count: 1,
                    },
                );
                false
            }
            Some(entry) if now < entry.end_time => {
                if entry.count < self.max_count {
                    // Case 2
                    entry.count += 1;
                    false
                } else {
                    // Case 3
                    true
                }
            }
            Some(entry) => {
                // Case 4
                entry.end_time = now + self.interval;
                entry.count = 1;
                false
            }
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() == 2 && args[1] == "test" {
        let key = "216.239.34.21:/api/v1/payroll_report";
        exercise_rate_limiter(key, 5, Duration::from_secs(2), 120);
        println!();
    } else {
        let key = "192.168.4.127:/api/v1/users";
        let mut limiter = RateLimiter::new(Duration::from_secs(5), 3);

        // false
        println!("{}", limiter.should_rate_limit(key));
        println!("{}", limiter.should_rate_limit(key));
        println!("{}", limiter.should_rate_limit(key));

        // true
        println!("{}", limiter.should_rate_limit(key));
    }
}

/// Drives the limiter through `windows` full windows, printing a dot for
/// each allowed request and a newline each time the limit is hit.
fn exercise_rate_limiter(key: &str, windows: u32, interval: Duration, max_count: u32) {
    let mut limiter = RateLimiter::new(interval, max_count);

    for window in 0..windows {
        loop {
            if !limiter.should_rate_limit(key) {
                // Not rate limited.
                print!(".");
                std::io::stdout().flush().unwrap();
                continue;
            }

            // Rate limited: end this window's output and, unless this was
            // the last window, poll until the next window opens.
            println!();
            if window < windows - 1 {
                loop {
                    std::thread::sleep(Duration::from_millis(10));
                    if !limiter.should_rate_limit(key) {
                        print!(".");
                        std::io::stdout().flush().unwrap();
                        break;
                    }
                }
            }
            break;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn allows_up_to_max_then_limits() {
        let mut limiter = RateLimiter::new(Duration::from_secs(5), 3);

        // Cases 1 and 2: first max_count requests are allowed.
        assert!(!limiter.should_rate_limit("key"));
        assert!(!limiter.should_rate_limit("key"));
        assert!(!limiter.should_rate_limit("key"));

        // Case 3: over the limit within the window.
        assert!(limiter.should_rate_limit("key"));
        assert!(limiter.should_rate_limit("key"));
    }

    #[test]
    fn keys_are_independent() {
        let mut limiter = RateLimiter::new(Duration::from_secs(5), 1);

        assert!(!limiter.should_rate_limit("a"));
        assert!(limiter.should_rate_limit("a"));

        // A different key gets its own window and counter.
        assert!(!limiter.should_rate_limit("b"));
    }

    #[test]
    fn window_expiry_resets_count() {
        let mut limiter = RateLimiter::new(Duration::from_millis(50), 2);

        assert!(!limiter.should_rate_limit("key"));
        assert!(!limiter.should_rate_limit("key"));
        assert!(limiter.should_rate_limit("key"));

        // Case 4: after the window expires, the count resets.
        std::thread::sleep(Duration::from_millis(60));
        assert!(!limiter.should_rate_limit("key"));
        assert!(!limiter.should_rate_limit("key"));
        assert!(limiter.should_rate_limit("key"));
    }

    #[test]
    fn expired_entries_are_evicted() {
        let mut limiter = RateLimiter::new(Duration::from_millis(10), 1);

        for i in 0..50 {
            assert!(!limiter.should_rate_limit(&format!("key{i}")));
        }
        assert_eq!(limiter.cache.len(), 50);

        // Let every window expire, then drive enough calls through a single
        // key to trigger the periodic sweep.
        std::thread::sleep(Duration::from_millis(20));
        for _ in 0..EVICT_EVERY {
            limiter.should_rate_limit("driver");
        }
        assert_eq!(limiter.cache.len(), 1);
        assert!(limiter.cache.contains_key("driver"));
    }
}

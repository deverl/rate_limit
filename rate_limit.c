// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

// For clock_gettime and nanosleep with -std=c11 -pedantic.
#define _POSIX_C_SOURCE 200809L

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// C has no standard library hash map, so the cache is a small hash
// table with separate chaining.
#define NUM_BUCKETS 64

// Sweep expired entries every Nth rateLimit call so stale keys
// don't accumulate forever.
#define EVICT_EVERY 100

typedef struct entry {
    char *key;
    double end_time; // Window end time (monotonic seconds)
    int count;       // Requests seen in the current window
    struct entry *next;
} entry;

static entry *cache[NUM_BUCKETS];
static long call_count = 0;

// Monotonic clock (seconds): unaffected by system clock adjustments,
// with sub-second precision.
static double monotonic_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

// djb2 string hash
static size_t hash_key(const char *key)
{
    unsigned long h = 5381;
    for (const char *p = key; *p != '\0'; p++) {
        h = h * 33 + (unsigned char)*p;
    }
    return h % NUM_BUCKETS;
}

static entry *find_entry(const char *key)
{
    for (entry *e = cache[hash_key(key)]; e != NULL; e = e->next) {
        if (strcmp(e->key, key) == 0) {
            return e;
        }
    }
    return NULL;
}

static void add_entry(const char *key, double end_time, int count)
{
    size_t bucket = hash_key(key);
    entry *e = malloc(sizeof(entry));
    e->key = strdup(key);
    e->end_time = end_time;
    e->count = count;
    e->next = cache[bucket];
    cache[bucket] = e;
}

static void evict_expired(void)
{
    double t = monotonic_time();
    for (size_t bucket = 0; bucket < NUM_BUCKETS; bucket++) {
        entry **link = &cache[bucket];
        while (*link != NULL) {
            entry *e = *link;
            if (t >= e->end_time) {
                *link = e->next;
                free(e->key);
                free(e);
            } else {
                link = &e->next;
            }
        }
    }
}

static bool rate_limit(const char *key, int interval, int max_count)
{
    call_count++;
    if (call_count % EVICT_EVERY == 0) {
        evict_expired();
    }

    double t = monotonic_time();
    entry *e = find_entry(key);

    if (e == NULL) {
        // Case 1
        add_entry(key, t + interval, 1);
        return false;
    }

    if (t < e->end_time) {
        // Not expired.
        if (e->count < max_count) {
            // Case 2
            e->count++;
            return false;
        }

        // Case 3
        return true;
    }

    // Case 4
    e->end_time = t + interval;
    e->count = 1;
    return false;
}

// Drives the limiter through `windows` full windows, printing a dot for
// each allowed request and a newline each time the limit is hit.
static void exercise_rate_limiter(const char *key, int windows, int interval, int max_count)
{
    struct timespec delay = {0, 10 * 1000 * 1000}; // 10 ms

    for (int i = 0; i < windows; i++) {
        for (;;) {
            if (!rate_limit(key, interval, max_count)) {
                // Not rate limited.
                printf(".");
                fflush(stdout);
                continue;
            }

            // Rate limited: end this window's output and, unless this was
            // the last window, poll until the next window opens.
            printf("\n");
            if (i < windows - 1) {
                for (;;) {
                    nanosleep(&delay, NULL);
                    if (!rate_limit(key, interval, max_count)) {
                        printf(".");
                        fflush(stdout);
                        break;
                    }
                }
            }
            break;
        }
    }
}

int main(int argc, char **argv)
{
    if (argc == 2 && strcmp(argv[1], "test") == 0) {
        const char *key = "216.239.34.21:/api/v1/payroll_report";
        exercise_rate_limiter(key, 5, 2, 120);
        printf("\n");
    } else {
        const char *key = "192.168.4.127:/api/v1/users";

        // false
        printf("%s\n", rate_limit(key, 5, 3) ? "true" : "false");
        printf("%s\n", rate_limit(key, 5, 3) ? "true" : "false");
        printf("%s\n", rate_limit(key, 5, 3) ? "true" : "false");

        // true
        printf("%s\n", rate_limit(key, 5, 3) ? "true" : "false");
    }

    return 0;
}

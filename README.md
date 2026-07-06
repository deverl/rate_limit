# Rate Limiter

## Overview

The programs in this project are possible implementations of a rate limiter.

### Notes
1. There are probably many ways this problem could be solved. These are just some examples.
2. All of the implementations are fixed-window counters, but the Java version differs slightly: its windows are calendar-aligned (boundaries fall on multiples of the interval), while the others start the window at the first request for a key. Both are valid variants, but they behave differently at window boundaries.
3. Each implementation sweeps expired entries out of its cache every 100th `rateLimit` call, so stale keys don't accumulate forever. A real system would typically rely on the cache's own TTL support (e.g. Redis `EXPIRE`).
4. Where the language makes it easy, the implementations use a monotonic clock (C `CLOCK_MONOTONIC`, C++ `steady_clock`, Rust `Instant`, Go's `time.Time`, Python `time.monotonic()`, JS `performance.now()`, PHP `hrtime()`), which is unaffected by system clock adjustments. Lua and Java/Kotlin still use the wall clock.

## Running

There is a makefile that can run each of the programs, building executables if required (go, c, cpp, java, rust).

You can run any of the programs with `make RUNTARGET` where `RUNTARGET` is one of:
- runc
- runcpp
- rungo
- runjava
- runlua
- runpython (or runpy)
- runjavascript (or runjs)
- runrust

The Rust version also has unit tests, which can be run with `make testrust` (or `cargo test` in the `rust/` directory). Like the Go and C versions, running the binary with a `test` argument (e.g. `./limitrust test`, `./limitc test`) exercises the limiter across several windows.

## Cleanup

There is also a make target to clean up all of the executables and intermediate files. Use `make clean` to cleanup.

## Caveats

In real world applications, you would want to use something like Redis for caching.

# Rate Limiter

## Overview

The programs in this project are possible implementations of a rate limiter.

### Notes
1. There are probably many ways this problem could be solved. These are just some examples.

## Running

There is a makefile that can run each of the programs, building executables if required (go, c, cpp, java).

You can run any of the programs with `make RUNTARGET` where `RUNTARGET` is one of:
- runcpp
- rungo
- runjava
- runlua
- runpython (or runpy)
- runjavascript (or runjs)

## Cleanup

There is also a make target to clean up all of the executables and intermediate files. Use `make clean` to cleanup.

## Caveats

In real world applications, you would want to use something like Redis for caching.


# Not all systems have a Fortran compiler; skip the Fortran version
# unless flang is on the PATH.
FLANG := $(shell command -v flang 2> /dev/null)

all : limitc limitcpp limitgo limitjava limitkt limitrust $(if $(FLANG),limitfortran)

.PHONY : clean runlua runpython runpy runjavascript runjs runphp rungo runrust runc runfortran runkotlin runkt


limitc : rate_limit.c makefile
	gcc -Wall -pedantic -O3 -std=c11 -o limitc rate_limit.c
	strip limitc


limitcpp : rate_limit.cpp makefile
	g++ -Wall -pedantic -O3 -std=c++11 -o limitcpp rate_limit.cpp
	strip limitcpp


limitgo: go/rate_limit.go makefile
	cd go ; go build -o limitgo ; mv limitgo ..


limitrust: rust/src/main.rs rust/Cargo.toml makefile
	cd rust ; cargo build --release ; cp "$${CARGO_TARGET_DIR:-target}/release/limitrust" ..


limitjava : RateLimit.jar makefile
	@echo '#!/usr/bin/env bash' > limitjava
	@echo 'java -jar RateLimit.jar "$$@"' >> limitjava
	@chmod a+x limitjava

RateLimit.jar: RateLimit.java makefile
	javac RateLimit.java
	echo "Main-Class: RateLimit" > MainClass.txt
	jar cmfv MainClass.txt RateLimit.jar *.class
	rm -f MainClass.txt *.class

limitkt.jar: kotlin/main.kt kotlin/RateLimit.kt kotlin/cache/Cache.kt kotlin/cache/CacheEntry.kt makefile
	cd kotlin ; kotlinc -include-runtime *.kt cache/*.kt -d ../limitkt.jar

limitkt: limitkt.jar
	@echo '#!/usr/bin/env bash' > limitkt
	@echo 'java -jar limitkt.jar "$$@"' >> limitkt
	@chmod a+x limitkt

limitfortran : rate_limit.f90 makefile
	flang -O2 -o limitfortran rate_limit.f90
	strip limitfortran


runall: runc runcpp runfortran rungo runjava runjs runkotlin runlua runphp runpy runrust



runc: limitc makefile
	./limitc


runcpp: limitcpp makefile
	./limitcpp


ifdef FLANG
runfortran: limitfortran makefile
	./limitfortran
else
runfortran:
	@echo "flang not found; skipping Fortran version"
endif


rungo: limitgo makefile
	./limitgo


runjava: limitjava
	./limitjava


runrust: limitrust makefile
	./limitrust


testrust:
	cd rust ; cargo test


runkotlin: limitkt
	./limitkt

runkt: runkotlin

runlua:
	lua rate_limit.lua


runpython:
	python3 rate_limit.py

runpy: runpython


runjavascript:
	node rate_limit.js

runjs: runjavascript


runphp:
	php rate_limit.php


clean:
	rm -rf limitc limitcpp limitfortran *.mod limitgo limitkt limitrust rust/target *.jar MainClass.txt *.class *.tmp.html a.out *.dSYM limitjava kotlin/*.class kotlin/cache/*.class kotlin/META-INF rate_limit.iml



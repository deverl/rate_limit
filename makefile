
all : limitc limitcpp limitgo rate_limit.jar

.PHONY : clean runlua runpython runpy runjavascript runjs runphp rungo


limitc : freq_nums.c makefile
	gcc -Wall -pedantic -O3 -o limitc freq_nums.c
	strip limitc


limitcpp : rate_limit.cpp makefile
	g++ -Wall -pedantic -O3 -std=c++11 -o limitcpp rate_limit.cpp
	strip limitcpp


limitgo: go/rate_limit.go makefile
	cd go ; go build -o limitgo ; mv limitgo ..


limitjava : rate_limit.jar
	@echo '#!/bin/bash' > limitjava
	@echo 'java -jar RateLimit.jar' >> limitjava
	@chmod a+x limitjava

rate_limit.jar: RateLimit.java makefile
	javac RateLimit.java
	echo "Main-Class: RateLimit" > MainClass.txt
	jar cmfv MainClass.txt RateLimit.jar *.class
	rm -f MainClass.txt *.class


runall: runc runcpp rungo runjava runjs runlua runphp runpy



runc: limitc makefile
	./limitc


runcpp: limitcpp makefile
	./limitcpp


rungo: limitgo makefile
	./limitgo


runjava: limitjava
	./limitjava


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
	rm -rf limitc limitcpp limitgo *.jar MainClass.txt *.class *.tmp.html a.out *.dSYM limitjava


#!/bin/bash

#lunch runs with the same nb pods
# warm up run
#./bench_10k.sh

#clearmeasured runs
for i in {1..3}
do
    ./bench_10k.sh >> 10k.json
done

#clean the output file
./cleaner.py

#print the test stats and plot graphs
./wjson.py

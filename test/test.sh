#!/bin/bash

#lunch runs with the same nb pods
# warm up
./bench_100p.sh

#measured runs
for i in {1..3}
do
    ./bench_100p.sh >> 100p.json
    #./bench_500p.sh > 500p.json
    #./bench_1000p.sh > 1000p.json
    #./bench_10000p.sh > 10000p.json
done

#clean the output file
python3 cleaner.py

#get the cleaned data and create graphs
python3 wjson.py

mv 100p.json data/data_100p.json

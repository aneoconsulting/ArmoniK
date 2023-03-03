#!/bin/bash

#lunch runs with the same nb pods
# warm up
./bench_10k_100p.sh

#measured runs
for i in {1..3}
do
    ./bench_10k_100p.sh >> 10k_100p.json
done

#clean the output file
python3 cleaner.py

#get the cleaned data and create graphs
python3 wjson.py

mv 10k_100p.json data/data_10k_100p.json

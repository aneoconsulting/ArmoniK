#!/bin/bash

#lunch runs with the same nb pods
# warm up
#./bench_10k.sh

#measured runs
for i in {1..3}
do
    ./bench_10k.sh >> 10k_1000p.json
done

#clean the output file
python3 cleaner.py

#stock the data
mv 10k_1000p.json data/data_10k_1000p.json

#get the cleaned data and create graphs
python3 wjson.py
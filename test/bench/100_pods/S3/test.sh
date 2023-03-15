#!/bin/bash

#lunch runs with the same nb pods
# warm up run
#./bench_10k.sh

#measured runs
for i in {1..1}
do
    ./bench_10k.sh >> 10k_0.11.4.json
    #./bench_100k.sh >> 100k_100p.json
done

#clean the output file
python3 cleaner.py

#stock the data
#have to test if the data/s3 repository exists else create it
mv 10k_0.11.4.json data/data_10k_100p_0.11.4.json

#get the cleaned data and create graphs
python3 wjson.py

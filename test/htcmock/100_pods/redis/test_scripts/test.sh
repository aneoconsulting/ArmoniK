#!/bin/bash

#lunch runs with the same nb pods
# warm up run
#./bench_10k.sh

#clearmeasured runs
#for i in {1..3}
#do
#    ./bench_10k.sh >> 10k.json
#done

./htcmock_5k.sh >> ../stats/4_agg/5k.json && 
#clean the output file
../python_scripts/cleaner.py 

#merge json files
#../python_scripts/merge_jsons.py

#print the test stats and plot graphs
#../python_scripts/wjson.py

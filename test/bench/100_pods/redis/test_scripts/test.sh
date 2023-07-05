#!/bin/bash

# warm up run
./bench_1k.sh

#clearmeasured runs
./bench_1k.sh >> ../stats/1k.json && ./bench_5k.sh >> ../stats/5k.json
#clean the output file
../python_scripts/cleaner.py

#merge json files
../python_scripts/merge_jsons.py

#print the test stats and plot graphs
#../python_scripts/wjson.py


#!/bin/bash

# warm up run
./bench_1k.sh

#clearmeasured runs
./bench_1k.sh >> ../stats/1k.json && ./bench_5k.sh >> ../stats/5k.json && ./bench_10k.sh >> ../stats/10k.json && ./bench_100k.sh >> ../stats/100k.json
#clean the output file
../python_scripts/cleaner.py

#merge json files
../python_scripts/merge_jsons.py

# save a pretty json file
jq . ../stats/results.json > ../stats/pretty_results.json

#print the test stats and plot graphs
#../python_scripts/wjson.py


#!/bin/bash

# warm up run
./htcmock_5k.sh

#clearmeasured runs
./htcmock_5k.sh >> ../stats/5k.json
#clean the output file
../python_scripts/cleaner.py 

#merge json files
../python_scripts/merge_jsons.py

# save and print pretty json file
jq . ../stats/results.json > ../stats/pretty_results.json
jq . ../stats/pretty_results.json

#print the test stats and plot graphs
#../python_scripts/wjson.py
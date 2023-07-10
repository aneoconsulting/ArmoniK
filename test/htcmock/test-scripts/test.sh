#!/bin/bash

# warm up run
./htcmock-5k.sh

#clearmeasured runs
./htcmock-5k.sh >> ../stats/5k.json
#clean the output file
../python-scripts/cleaner.py 

#merge json files
../python-scripts/merge-jsons.py

# save and print pretty json file
jq . ../stats/results.json > ../stats/pretty-results.json
jq . ../stats/pretty-results.json

#print the test stats and plot graphs
#../python-scripts/wjson.py
# HOW TO USE IT

This document describe how to use the benchmarking scripts.

## Bench

### Run the tests

* Scripts for each test
* Script to run all the tests cases and  store the results in Json files

### Clean the output

cleaner.py will clean the json output files.
* Parameters : path to the json files we want to clean
merge_jsons.py : merges test_env.json is a json file which describes the test environment(third party components of ArmoniK) and we have to set it for each test with the parameters json file of the tested version of ArmoniK with the clean results of the test. 

### Analyse the results 

wjson will read the clean json files and calculate the results.

* Parameters : List of clean json files

### How to use it :
Run the script test.sh to run the tests, store the outputs, clean them and merge them with the environment and infrastructure description files.
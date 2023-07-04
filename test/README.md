# HOW TO USE IT

This document describes how to use the benchmarking scripts. 


#### Folder tree

<pre>
.  
├── bench    
|  └── 100_pods  
|        └── redis  
|            ├── python_scripts  
|            |   ├── cleaner.py  
|            |   ├── merge_jsons.py  
|            |   └── wjson.py  
|            ├── stats  
|            |   └── test_env.json  
|            └── test_scripts  
|                ├── bench_1k.sh  
|                ├── bench_5k.sh  
|                └── test.sh  
├── htcmock  
|   └── 100_pods  
|        └── redis  
|            ├── python_scripts  
|            |   ├── cleaner.py  
|            |   ├── merge_jsons.py  
|            |   └── wjson.py  
|            ├── stats  
|            |   └── test_env.json  
|            └── test_scripts  
|                ├── htcmock_5k.sh  
|                └── test.sh  
├── README.md  

</pre>

## Bench and Htcmock

### Run the tests

* bench_1k.sh & bench_5k.sh : scripts for each test where we set the parameters of the test to run.
* test.sh : script to run all the tests cases and  store the results in Json files.

### Clean the output

* cleaner.py : will clean the json output files.  
Parameters : path to the json files we want to clean.  


* merge_jsons.py : merges the cleaned results files with the parameters json file of the tested version of ArmoniK and est_env.json file (third party components of ArmoniK).
* prerequisites: we have to install jsonmerge (pip install jsonmerge)

### Analyse the results 

wjson.py : will read the clean stats files so we can manipulate the data.

* Parameters : List of clean json files

### How to use it :
* Run the script test_scripts/test.sh to run the tests, store the outputs, clean them and merge them with the environment and infrastructure description files.



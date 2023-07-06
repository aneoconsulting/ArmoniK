# HOW TO USE IT

This document describes how to use the benchmarking scripts.

Those tests are an example of benchmarking tests using bench and htcmock to measure the performances of ArmoniK.  
We have to deploy [ArmoniK(aws-benchmark)](https://github.com/aneoconsulting/ArmoniK/tree/yk/benchmarking_scripts/infrastructure/quick-deploy/aws-benchmark) on aws with two partitions (bench and htcmock) with 100 pods for each partition
using redis as storage.

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
|            |   └── merge_jsons.py  
|            |     
|            ├── stats  
|            |   └── test_env.json  
|            └── test_scripts  
|                ├── htcmock_5k.sh  
|                └── test.sh  
├── README.md  

</pre>

# Bench & Htcmock

### Run the tests

* bench_1k.sh & bench_5k.sh : scripts for each test where we set the parameters of the test to run.
* test.sh : script to run all the tests cases and store the results in Json files.

### Clean the output

* cleaner.py : will clean the json output files.  

* merge_jsons.py : merges the cleaned results files with the parameters json file of the tested version of ArmoniK and
  est_env.json file (third party components of ArmoniK).
* prerequisites: install jsonmerge
```console
user@user:~$ pip install jsonmerge
```


### Analyse the results

* wjson.py : will read the clean stats files, so we can manipulate the data of bench tests.

### How to run the tests :

#### Linux :

* Run the script test.sh in the directory /test/bench/100_pods/redis/test_scripts to run the tests of bench, store the
  outputs, clean them and merge them with the environment and infrastructure description files.
* Run the script test.sh in the directory /test/htcmock/100_pods/redis/test_scripts to run the tests of htcmock, store
  the outputs, clean them and merge them with the environment and infrastructure description files.

```console
user@user:~$ ./test.sh
```

# Stresstest :

TODO:

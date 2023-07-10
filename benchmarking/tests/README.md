# HOW TO USE IT

This document describes how to use the benchmarking scripts.

These tests are examples of benchmarking based on  Bench and HtcMock tests to measure the performances of ArmoniK.   
We have to deploy ArmoniK on AWS cloud using the parameters files saved in folder [aws-benchmark](https://github.com/aneoconsulting/ArmoniK/tree/main/benchmarking_scripts/infrastructure/quick-deploy/aws-benchmark) to deploy ArmoniK with two partitions (bench and htcmock) with 100 pods or 1000 pods for each partition.

# Deploy ArmoniK on AWS cloud  
To deploy ArmoniK on AWS cloud with 100 pods of compute plane, from the root of the repository : 
```bash
cd infrastructure/quick-deploy/aws/all  
make deploy PARAMETERS_FILE=<Path to ArmoniK>/infrastructure/quick-deploy/aws-benchmark/parameters_100pods.tfvars
```
To deploy ArmoniK on AWS cloud with 1000 pods of compute plane, from the root of the repository : 
```bash
cd infrastructure/quick-deploy/aws/all  
make deploy PARAMETERS_FILE=<Path to ArmoniK>/infrastructure/quick-deploy/aws-benchmark/parameters_1000pods.tfvars
```
# Global view test scripts tree

From the root of the repository, the scripts of bench and htcmock tests are in [benchmarking/tests](https://github.com/aneoconsulting/ArmoniK/tree/main/benchmarking/tests) as follows : 

<pre>
.
├── bench
│   ├── python-scripts
│   │   ├── cleaner.py
│   │   ├── merge-jsons.py
│   │   └── wjson.py
│   ├── stats
│   │   └── test-env.json
│   └── test_scripts
│       ├── bench-100k.sh
│       ├── bench-10k.sh
│       ├── bench-1k.sh
│       ├── bench-5k.sh
│       ├── htcmock-1m.sh
│       └── test.sh
├── htcmock
│   ├── python-scripts
│   │   ├── cleaner.py
│   │   └── merge-jsons.py
│   ├── stats
│   │   └── test-env.json
│   └── test-scripts
│       ├── htcmock-1k.sh
│       ├── htcmock-5k.sh
│       ├── htcmock-10k.sh
│       ├── htcmock-100k.sh
│       ├── htcmock-1m.sh
│       └── test.sh
└── README.md
</pre>

# Bench & HtcMock

## Run the tests

* * `bench-1k.sh`, `bench-5k.sh`, `bench-10k.sh`, `bench-100k.sh` and  `bench-1m.sh`: bash scripts to launch bench tests with 1000 tasks, 5000 tasks, 10000 tasks, 100000 tasks and 1000000 tasks, respectively. In addition, you can modify in the scripts other parameters like workload time, io size, ...
* `test.sh` : script to run all the tests cases listed above and store the results in JSON files.

### Clean the output

* cleaner.py : will clean the json output files.  

* merge_jsons.py : merges the cleaned results files with the parameters json file of the tested version of ArmoniK and
  est_env.json file (third party components of ArmoniK).
* prerequisites: install jsonmerge
```bash
pip install jsonmerge
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
./test.sh
```

# Stresstest :

TODO:

 # Test plan of Armonik "2.12.0"

-[Introduction](#Introduction)

-[The product and the functionalities to test](#the-product-and-the-functionalities-to-test)

-[Prerequisite and exigences](#prerequisite-and-exigences)

-[The tools used to do the tests](#the-tools-used-to-do-the-tests)

-[Tests environment](#Tests-environment)

-[Exploited ressources](#exploited-ressources)

-[The estimated results](#the-estimated-results)

-[Tests to do](#tests-to-do)

# Introduction

This test plan describes the performance tests of ArmoniK. The purpose of those tests is to mesure the performance of the differents functionalities of ArmoniK (Tasks submission, Tasks treatment, ...). For this, we will do different tests:
- Measure the execution time of different numbers of submitted tasks and different size of the tasks.
- Test the strong scalability.

The purpose of those tests is to have performance measurements in function of the ArmoniK versions. Since this is the first iteration of the performances tests we are going to establish our baseline in function of a specific versions (see after).

# The product and the functionalities to test

## Products

### Stresstest "2.12.0"

This test is a stress test which runs a number of tasks with a specific i/o sizes and duration of the tasks. It uses ArmoniK's c# extension. It copies a zip of the dlls of the application and install them on the workers.

### Bench "0.11.4"

This test is similar to StressTest but it doesn't use ArmoniK's c# extension, it means that the application is already in the docker image of the workers.

## HtcMock "0.11.4" 

With this test we can have an idea of how ArmoniK can handle the applications with subtasking and aggregation tasks.

## functionalities

- The submission of the tasks
- The processing of the tasks
- The retrieving of the results 

# Prerequisite and exigences

- Deploy ArmoniK with different partitions of bench (different number of pods in each partition)

# The tools used to do the tests

## Scripts bash

- To start a warming up run then a batch of runs with the same parameters and store them in files

## Python

- Clean the files where we stored the data in readable json files.
- Read the data and compute the median and the mean of each run batch.

## Json 

- We store the results of the performance tests in Json file which we will store in a database.

# Tests environment

- ArmoniK deployed on AWS via WSL2

| Date | Infra version | Core version | API version  | Extension c# version | Instance type | Instance caracteristics | CPU frequency | nb vCPUs | RAM (GB) | Network bandwidth (Gbps) | EBS Bandwidth (Mbps) |
| :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---   |  :---   |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 |

- [Config file](https://github.com/aneoconsulting/ArmoniK/blob/874-benchmarking/versions.tfvars.json) with all the versions of Armonik

# Exploited ressources

| Kubernetes | object storage type | storage queue type | storage table type | OS |
| :---    | :---    | :---    | :---    | :---    |
| AWS EKS "1.25" | AWS S3 | Amazon MQ, broker : ActiveMQ "5.16.4" | MongoDB "6.0.1" | Linux |

# The estimated results

- More pods -> faster treatement 

# Tests to do

## Throughput scalability tests

- 1000 tasks on : 100 pods, 1000 pods, and 10000 pods
- 5000 tasks on : 100 pods, 1000 pods, and 10000 pods
- 10k tasks on : 100 pods, 1000 pods, and 10000 pods
- 100k tasks on : 100 pods, 1000 pods, and 10000 pods
- 1M tasks on : 100 pods, 1000 pods, and 10000 pods

### with

- tasks duration : 1 ms
- payload size : 8B
- result size : 8B

#### StressTest

| nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B  |  |  |  |  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |

#### Bench

| nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |

#### HtcMock

| nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | Sub tasks level | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |


## Submission scalability tests

- Number of pods : 1000
- Tasks duration : 500 ms
- Result size : 100KB

#### StressTest

| nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |


## Other tests
    
| nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 80K | 200m  | 1000m | 1000m | 2000m | 1 | 2000m | 300M | 1s | 1KB | 1KB |  |  |  |  |  |  |  |  |
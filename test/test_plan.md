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
This test plan describes the performance tests of ArmoniK. The purpose of those tests is to mesure the performance of the differents functionnalities of ArmoniK(Tasks submission, Tasks treatement,...).For this, we will do different tests:
- Measure the execution time of different numbers of submitted tasks and different size of the tasks.
- Test the strong scalability.

The purpose of those tests is to have a reference numbers and performance of the versions of ArmoniK.

# The product and the functionalities to test
## Products
- Bench "0.11.4" , Stresstest "2.12.0" on ArmoniK "2.12.0"
- The submission of the tasks
- The processing of the tasks
- The retrieving of the results 

# Prerequisite and exigences
- Deploy ArmoniK with different partitions of bench (different number of pods in each partition)

# The tools used to do the tests
## Scripts bash
- To lunch a warming up run then a bunch of runs with the same parameters and store them in files
## Python:
- Clean the files where we stocked the data in readable json files.
- Read the data and calculate the median and the mean of each run bunch.
## Json :
- We stock the results of the performance tests in Json file wich we will store in a database.

# Tests environment
- ArmoniK deployed on AWS via WSL2

# Exploited ressources
- Kubernetes : AWS EKS "1.25"
- The object storage type : AWS S3
- The storage queue type : Amazon MQ, broker : ActiveMQ "5.16.4"
- The storage table type : MongoDB "6.0.1"
- the OS type : Linux ""
- Instance Type : c24.xlarge

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
- The tasks duration : 1 ms
- The payload size : 8B
- The result size : 8B

#### StressTest

| Date | Infra version | Core version | API version  | Extension c# version | Instance type | Instance caracteristics | CPU frequency | nb vCPUs | RAM (GB) | Network bandwidth (Gbps) | EBS Bandwidth (Mbps) | nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---   |  :---    | :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B  |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |

#### Bench

| Date | Infra version | Core version | API version  | Extension c# version | Instance type | Instance caracteristics | CPU frequency | nb vCPUs | RAM (GB) | Network bandwidth (Gbps) | EBS Bandwidth (Mbps) | nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---   |  :---    | :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 10000 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1 ms | 8B | 8B |  |  |  |  |


## Submission scalability tests
- Number of pods : 1000
- The tasks duration : 500 ms
- The result size : 100KB

#### StressTest

| Date | Infra version | Core version | API version  | Extension c# version | Instance type | Instance caracteristics | CPU frequency | nb vCPUs | RAM (GB) | Network bandwidth (Gbps) | EBS Bandwidth (Mbps) | nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---   |  :---    | :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 10K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000m | 1000m | 2000m | 50m | 1000m | 100K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 100 | 200m  | 1000m | 1000m | 2000m | 50m | 1000m | 1M | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |



## Other tests : 
    
| Date | Infra version | Core version | API version  | Extension c# version | Instance type | Instance caracteristics | CPU frequency | nb vCPUs | RAM (GB) | Network bandwidth (Gbps) | EBS Bandwidth (Mbps) | nb pods | nb cores per control-plane| limits nb cores per control-plane| nb cores per scheduler-agent| limits nb cores per scheduler-agent| nb cores per worker | limits nb cores per worker | nb tasks | task duration | input payload | result payload | Duration of submission (s) | Upload speed (s) | Throughtput for submission (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---    | :---   |  :---    | :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 03/29/2023 | 2.12.0 | 0.11.1 | 3.5.2 | 0.9.1 | c24.xlarge |  Intel Xeon de 2e (Cascade Lake) | 3.6 GHz - 3.9 GHz | 96 | 192 | 25 | 19000 | 80K | 200m  | 1000m | 1000m | 2000m | 1 | 2000m | 300M | 1s | 1KB | 1KB |  |  |  |  |  |  |  |  |
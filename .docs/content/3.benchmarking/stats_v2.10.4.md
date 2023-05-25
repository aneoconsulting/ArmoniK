# Introduction

In this document we present the performances of the ArmoniK version 2.10.4.

# Test plan

The benchmarks realised here follow the [test plan](./0.test_plan.md).

# Tests environment

These tests are dependent of the configuration of the underlying infrastructure and are a prerequirement of every test execution used as comparison. This method could be reused as reproducer for anyone desiring to execute our tests.

|        |       |
| ------ | ----- |
| **Date** | 05/23/2023 |
| **Infra version** |  2.10.4 |
| **Core version** | 0.8.3 |
| **API version** | 3.2.1 |
| **Extension c# version** | 0.8.2.1 |
| **Metrics exporter** | 0.8.3 |
| **StressTest Client** | 2.10.4 |
| **Bench Client** | 0.8.3 |
| **HtcMock Client** | 0.8.3 |
| **Instance type** | c24.xlarge |
| **Processor** | Intel Xeon de 2e (Cascade Lake) |
| **CPU frequency** | 3.6 GHz - 3.9 GHz |
| **nb vCPUs** |  96 |
| **RAM (GB)** | 192 |
| **Network bandwidth (Gbps)** | 25 |
| **EBS Bandwidth (Mbps)** | 19000 |

The versions of the different ArmoniK components and the third-party tools are defined in [versions.tfvars.json](https://github.com/aneoconsulting/ArmoniK/blob/v2.12.3/versions.tfvars.json).

# Exploited ressources

| Kubernetes | Object stroage type | Storage queue type | Storage table type | OS |
| :---    | :---    | :---    | :---    | :---    |
| AWS EKS "1.22" | Redis | Amazon MQ, broker : ActiveMQ "5.16.4" | MongoDB "5.0.9" | Linux |

# The estimated results

Faster task processing by increasing the number of pods.

# Tests to do

## Throughput scalability tests

- 1000 tasks on : 100 pods, 1000 pods and 10000 pods
- 5000 tasks on : 100 pods, 1000 pods and 10000 pods
- 10K tasks on : 100 pods, 1000 pods and 10000 pods
- 100K tasks on : 100 pods, 1000 pods and 10000 pods
- 1M tasks on : 100 pods, 1000 pods and 10000 pods

### with

- Tasks duration : 1 ms
- Input payload size : 8B
- Output payload size : 8B

#### StressTest

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B   |  |   |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  |  |  |   |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |   |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B|  |  |   |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |   |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |   |  |  |  |  |  |  |

#### Bench

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Total time (s)|
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 3.14 | 22.15 |  | 25.14 | 50.61 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 15.37 | 111.88 |  | 121.47 | 249.07 |  
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 29.05 | 215.22 |  | 241.32 | 485.7 |  
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mii | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  | **-** | **-** | **-** | **-** | **-** |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 5.24 | 21.98 |  | 22.74 | 50.68 |  
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 18.99 | 109.93 |  | 122.7 | 251.93 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B| 45.01 | 585.75 |  | 244.82 | 515.77 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |

##### Results analysis

- The throughput column is empty because the bench client doesn't return the throughput metric in this version.
- We don't have stats for the tests with the number of tasks greater than 10k tasks because the bench client can't handle the results retrieving of a higher number of tasks.

#### HtcMock

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Aggregation level | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CCPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |

## Submission scalability tests

- Number of pods : 1000
- Tasks duration : 500 ms
- Output payload size : 8B

### StressTest

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi |CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |  |

## Other tests

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 80K | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | 1 | CPU: 1000m / Memory: 2048Mi | 300M | 1s | 1KB | 1KB |  |  |  |  |  |  |  |  |  |

This document will be completed in the future with more tests to target more detailed and deeper ArmoniK's features and components.

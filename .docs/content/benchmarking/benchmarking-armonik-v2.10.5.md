# Benchmarking ArmoniK v2.10.5

In this document we present the performances of the ArmoniK version 2.10.5.



```{note}


The benchmarks follow the [Test Plan](./test-plan.md).

```

## Tests environment

These tests are dependent of the configuration of the underlying infrastructure and are a prerequirement of every test execution used as comparison. This method could be reused as reproducer for anyone desiring to execute our tests.

|        |       |
| ------ | ----- |
| **Date** | 05/23/2023 |
| **Infra version** |  2.10.5 |
| **Core version** | 0.8.4 |
| **API version** | 3.2.1 |
| **Extension c# version** | 0.8.2.1 |
| **Metrics exporter** | 0.8.4 |
| **StressTest Client** | 2.10.5 |
| **Bench Client** | 0.8.4 |
| **HtcMock Client** | 0.8.4 |
| **Instance type** | c24.xlarge |
| **Processor** | Intel Xeon de 2e (Cascade Lake) |
| **CPU frequency** | 3.6 GHz - 3.9 GHz |
| **nb vCPUs** |  96 |
| **RAM (GB)** | 192 |
| **Network bandwidth (Gbps)** | 25 |
| **EBS Bandwidth (Mbps)** | 19000 |

## Exploited ressources

| Kubernetes | Object storage type | Storage queue type | Storage table type | OS |
| :---    | :---    | :---    | :---    | :---    |
| AWS EKS "1.22" | Redis | Amazon MQ, broker : ActiveMQ "5.16.4" | MongoDB "5.0.9" | Linux |

## The estimated results

Faster task processing by increasing the number of pods.

## Tests to do

### Throughput scalability tests

- 1000 tasks on 100 pods, 1000 pods and 10000 pods
- 5000 tasks on 100 pods, 1000 pods and 10000 pods
- 10K tasks on 100 pods, 1000 pods and 10000 pods
- 100K tasks on 100 pods, 1000 pods and 10000 pods
- 1M tasks on 100 pods, 1000 pods and 10000 pods

with the following parameters:

- Tasks duration: 1 ms
- Input payload size: 8B
- Output payload size: 8B

#### StressTest

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B   |  |   |  |  |  |  |  |  |  |
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
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 2.96 | 23.48 |  | 24.18 | 50.94 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 17.99 | 117.48 |  | 127.42 | 263.08 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 31.62 | 225.54 |  | 248.18 | 505.52 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mii | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  | **-** | **-** | **-** | **-** | **-** |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 4.39 | 23.52 |  | 23.73 | 52.38 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 19.97 | 110.1 |  | 122.81 | 253.1 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 44.87 | 227.92 |  | 250.01 | 523.09 |
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

### Submission scalability tests

- Number of pods: 1000
- Tasks duration: 500 ms
- Output payload size: 8B

#### StressTest

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
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

#### Other tests

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughput for retrieving results (tasks/s) | Download speed (s) | Total time (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 80K | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | 1 | CPU: 1000m / Memory: 2048Mi | 300M | 1s | 1KB | 1KB |  |  |  |  |  |  |  |  |  |

This document will be completed in the future with more tests to target more detailed and deeper ArmoniK's features and components.

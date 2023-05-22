 # Table of contents 
- [Introduction](#Introduction)
- [Test-plan](#Test-plan)
- [Tests environment](#Tests-environment)
- [Exploited ressources](#exploited-ressources)
- [The estimated results](#the-estimated-results)
- [Tests to do](#tests-to-do)

# Introduction
In this document we present the performances of the ArmoniK version 2.12.3.

# Test plan
The benchmarks realised here follow the [test plan](../test_plan.md).

# Tests environment
These tests are dependent of the configuration of the underlying infrastructure and are a prerequirement of every test execution used as comparison. This method could be reused as reproducer for anyone desiring to execute our tests.

|        |       |
| ------ | ----- |
| **Date** | 05/01/2023 |
| **Infra version** |  2.12.3 |
| **Core version** | 0.12.4 |
| **API version** | 3.5.2 |
| **Extension c# version** | 0.9.5 |
| **Metrics exporter** | 0.12.4 |
| **StressTest Client** | 2.12.3 |
| **Bench Client** | 0.12.4 |
| **HtcMock Client** | 0.12.4 |
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
| AWS EKS "1.25" | Redis | Amazon MQ, broker : ActiveMQ "5.16.4" | MongoDB "6.0.1" | Linux |

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
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 1 | 7.79 | 997.74 | 3.63 | 274.80 | 22.67 | 44.1 | 0.34 | 23.41 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 4.53 | 8.61 | 1101.45 | 4.89 | 1022.29 | 97.3 | 51.38 | 0.40 | 98.11 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 9.91 | 7.88 | 1008.70 | 9.55 | 1046.57 | 195.72 | 51.09 | 0.40 | 196.46 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B | 96.52 | 8.09 | 1035.96 | 96.18 | 1039.62 | 1740.38 | 57.46 | 0.45 | 1741.16 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  | **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 1.81 | 4.31 | 552.26 | 8.11 | 123.30 | 23.92 | 41.80 | 0.33 | 25.06 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 3.36 | 11.59 | 1483.88 | 6.48 | 770.89 | 101 | 49.50 | 0.39 | 101.71 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 27.92 | 2.80 | 358.14 | 27.01 | 370.11 | 363 | 27.55 | 0.22 | 364.4 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| 240.66 | 3.25 | 415.52 | 240.05 | 416.58 | 2661.68 | 37.57 | 0.29 | 2662.67 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m/ Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B| **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-**  | **-** | **-** | **-** | **-** | **-** | **-** |

#### Bench
| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Total time (s)|
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 5.32 | 10.81 | 195.54 | 2.79 | 19.21 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 21.50 | 57.81 | 233.44 | 15.71 | 95.05 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B | 48.14 | 174.32 | 208.32 | 51.63 | 274.14 |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mii | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  | **-** | **-** | **-** | **-** | **-** |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | 7.35 | 14.90 | 131.32 | 3.87 | 26.57 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi| CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | 24.21 | 71.84 | 207.46 | 19.16 | 114.27 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B| 49.91 | 129.70 | 200.73 | 33.39 | 213.04 |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi |CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B| **-** | **-** | **-** | **-** | **-** |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 1000m / Memory: 256Mi | CPU: 2000m  / Memory: 2048Mi | CPU: 500m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B | **-** | **-** | **-** | **-** | **-** |

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

#### StressTest
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
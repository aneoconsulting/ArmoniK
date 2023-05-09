# Test plan of Armonik

- [Introduction](#introduction)
- [The product and the functionalities to test](#the-product-and-the-functionalities-to-test)
- [The tools used to do the tests](#the-tools-used-to-do-the-tests)
- [Tests environment](#tests-environment)
- [Exploited ressources](#exploited-ressources)
- [The estimated results](#the-estimated-results)
- [Tests to do](#tests-to-do)

# Introduction

In this document we describe a performance test plan of ArmoniK. The purpose is to measure the performance of the different functionalities of ArmoniK (task submissions, processing of tasks, ...). We will perform the following tests:
- Measure the execution time of different numbers of submitted tasks and different size of the tasks.
- The strong scaling.

The purpose of these tests is to have performance measurements based on ArmoniK versions. As this is the first iteration of the performance tests, we will establish our baseline based on a specific version (see hereafter).

# The product and the functionalities to test

## Products

### Stresstest

This is a stress test which runs a number of tasks with a specific I/O sizes and task workloads. It uses ArmoniK C# extension which copies the DLLs of the application as a zip and installs them on the workers.

### Bench

This test is similar to StressTest but it doesn't use ArmoniK C# extension. The application is already installed on the workers.

### HtcMock

With this test we can have an idea of how ArmoniK can handle the applications with subtasking and aggregation tasks.

## functionalities

We want to test in this first iteration, the three main functionnalities of ArmoniK described below.

### The submission of the tasks

With these tests, we want to measure the performances of tasks submissions od ArmoniK. This is the first step of the task ochestration which consists in submitting the tasks and the input data to be processed by ArmoniK workers.

### The processing of the tasks

In addition to the tasks submission, these tests will allow us to measure the ArmoniK ability to process different numbers of tasks with different workload durations.

### The retrieving of the results

These tests will allow us to determine ArmoniK performances to retrieve the results data after tasks processing. This step consists in the recovery of the output data after the processing of the tasks and it is the last step of the task orchestration.

# The tools used to do the tests

## Bash scripts

The scripts start a warming up run, launch a batch of runs with the same parameters, and store performance data in files.

## Python

- Clean the files of the performance data and store them in readable JSON files.
- Compute the median and the mean of each batch of runs

## JSON

We store the results of the performance tests in JSON files which we will be stored in a database.

# Tests environment

These tests are dependent of the configuration of the underlying infrastructure and are a prerequirement of every test execution used as comparison. This method could be reused as reproducer for anyone desiring to execute our tests.

|        |       |
| ------ | ----- |
| **Date** | 03/29/2023 |
| **Infra version** |  2.12.0  |
| **Core version** | 0.11.1 |
| **API version** | 3.5.2 |
| **Extension c# version** | 0.9.1 |
| **Instance type** | c24.xlarge |
| **Processor** | Intel Xeon de 2e (Cascade Lake) |
| **CPU frequency** | 3.6 GHz - 3.9 GHz |
| **nb vCPUs** |  96 |
| **RAM (GB)** | 192 |
| **Network bandwidth (Gbps)** | 25 |
| **EBS Bandwidth (Mbps)** | 19000 |

The versions of the different ArmoniK components and the third-party tools are defined in [versions.tfvars.json](https://github.com/aneoconsulting/ArmoniK/blob/v2.12.0/versions.tfvars.json).

# Exploited ressources

| Kubernetes | Object stroage type | Storage queue type | Storage table type | OS |
| :---    | :---    | :---    | :---    | :---    |
| AWS EKS "1.25" | AWS S3 | Amazon MQ, broker : ActiveMQ "5.16.4" | MongoDB "6.0.1" | Linux |

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

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  |  |  |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |  |  |  |  |  |  |

#### Bench

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1 ms | 8B | 8B |  |  |  |  |

#### HtcMock

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Aggregation level | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 1000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1K | 1 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 5K | 5 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10 | 1 ms | 8B | 8B |  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100 | 1 ms | 8B | 8B|  |  |  |  |
| 10000 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1000 | 1 ms | 8B | 8B  |  |  |  |  |

## Submission scalability tests

- Number of pods : 1000
- Tasks duration : 500 ms
- Output payload size : 8B

## StressTest

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 10K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 100K | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 1KB | 5 | 1 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 10KB | 5 | 5 |  |  |  |  |  |  |  |  |
| 100 | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1M | 100KB | 5 | 10 |  |  |  |  |  |  |  |  |

## Other tests

| Number of pods | Resource requests per control-plane| Resource limits per control-plane| Resource requests per scheduling-agent| Resource limits per scheduling-agent| Resource requests per worker | Resource limits for per worker | Number of tasks | Task workload duration | Input payload size | Output payload size | Duration of submissions (s) | Upload speed (s) | Throughtput for submissions (tasks/s) | Duration of processing (s) | Throughput for processing (tasks/s) | Duration of retrieving results (s) | Throughtput for retrieving results (tasks/s) | Download speed (s) |
| :---    | :---    | :---    | :---   |  :---   |  :----:  |    ---: |  :----:  |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |    ---: |
| 80K | CPU: 200m / Memory: 512Mi  | CPU: 1000m / Memory: 2048Mi | CPU: 200m / Memory: 512Mi | CPU: 1000m / Memory: 2048Mi | 1 | CPU: 1000m / Memory: 2048Mi | 300M | 1s | 1KB | 1KB |  |  |  |  |  |  |  |  |

This document will be completed in the future with more tests to target more detailed and deeper ArmoniK's features and components.

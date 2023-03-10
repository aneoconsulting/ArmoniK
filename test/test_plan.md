 # Test plan of Armonik "2.11.0"
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
- Measure the execution time on different numbers of submitted tasks and different size of the tasks.
- Test the strong scalability.

The purpose of those tests is to have a reference numbers and performance of this version of ArmoniK to know exactly what ArmoniK can do now. Also keep the numbers in order to compare them with a future realisations.


# The product and the functionalities to test
## Products
- Bench "0.11.2" on ArmoniK "2.11.0"


# Prerequisite and exigences
- deploy ArmoniK with different partitions of bench (different number of pods in each partition)

# The tools used to do the tests
## Scripts bash
- To lunch a warming up run then a bunch of runs with the same parameters and store them in files
## Python:
- Clean the files where we stocked the data in readable json files.
- read the data and calculate the median and the mean of each run bunch.
## Json :
- We stock the results of the performance tests in Json file wich we will store in a database.

# Tests environment
- ArmoniK deployed on AWS via WSL2

# Exploited ressources
- ressources AWS(eks "1.25","elasticache","amazonMQ")

# The estimated results
- more pods -> faster treatement 

# Tests to do
## Bench
- Scalability tests:
    - 10k tasks on : 100 pods, 1000 pods, and 10000 pods
    - 100k tasks on : 100 pods, 1000 pods, and 10000 pods
    - 1M tasks on : 100 pods, 1000 pods, and 10000 pods
    ## with
    - The tasks duration : 10 ms
    - The payload size : 100 KB
    - The result size : 100 KB

- Performance tests with a fix number of pods (100 pods) with and variable parameters:
    - The number of tasks
    - The tasks durations
    - The payload size
    - The result size
    - 80k tasks, 1s per task, 1cpu per worker
    - redis vs s3 (core 0.11.2 vs 0.11.3)

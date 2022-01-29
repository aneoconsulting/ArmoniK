# Table of contents
1. [ArmoniK](#armonik)
   1. [When should I use ArmoniK](#when-should-i-use-armonik)
   2. [When should I not use ArmoniK](#when-should-i-not-use-armonik)
2. [ArmoniK deployment](#armonik-deployment)
3. [How to run ArmoniK.Samples](#how-to-run-armonik.samples)

# ArmoniK
<em>ArmoniK</em> is a high throughput compute grid project using Kubernetes. 
The project provides a reference architecture that can be used to build and adapt a modern high throughput compute
solution on-premise or using Cloud services, allowing users to submit high volumes of short and long-running tasks
and scaling environments dynamically.

**Warning**: This project is an Open Source (Apache 2.0 License).

## When should I use ArmoniK
ArmoniK should be used when the following criteria are meet:
1. A high task throughput is required (from 250 to 10,000+ tasks per second).
2. The tasks are loosely coupled.
3. Variable workloads (tasks with heterogeneous execution times) are expected and the solution needs to 
   dynamically scale with the load.

## When should I not use ArmoniK 
ArmoniK might not be the best choice if :
1. The required task throughput is below 250 tasks per second.
2. The tasks are tightly coupled, or use MPI.
3. The tasks use third party licensed software.

# ArmoniK deployment
All instructions to build, deploy and test ArmoniK software on Linux are described in [ArmoniK deployment](./infrastructure/README.md)

# How to run ArmoniK.Samples
Instructions to run ArmoniK.Samples are described in [Run Samples](https://github.com/aneoconsulting/ArmoniK.Samples/blob/main/README.md)
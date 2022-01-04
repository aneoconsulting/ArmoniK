# Table of contents
1. [ArmoniK](#armonik)
   1. [When should I use ArmoniK](#when-should-i-use-armonik)
   2. [When should I not use ArmoniK](#when-should-i-not-use-armonik)
2. [ArmoniK deployment](#armonik-deployment)
3. [How to run ArmoniK.Samples](#how-to-run-armonik.samples)

# ArmoniK <a name="Armonik"></a>
<em>ArmoniK</em> is a high throughput compute grid project using Kubernetes. 
The project provides a reference architecture that can be used to build and adapt a modern high throughput compute
solution on-premise or using Cloud services, allowing users to submit high volumes of short and long running tasks
and scaling environments dynamically.

**Warning**: This project is an Open Source (Apache 2.0 License).

## When should I use ArmoniK <a name="when-should-i-use-armonik"></a>
ArmoniK should be used when the following criteria are meet:
1. A high task throughput is required (from 250 to 10,000+ tasks per second).
2. The tasks are loosely coupled.
3. Variable workloads (tasks with heterogeneous execution times) are expected and the solution needs to 
   dynamically scale with the load.

## When should I not use ArmoniK <a name="when-should-i-not-use-armonik"></a>
ArmoniK might not be the best choice if :
1. The required task throughput is below 250 tasks per second.
2. The tasks are tightly coupled, or use MPI.
3. The tasks uses third party licensed software.

# ArmoniK deployment <a name="armonik-deployment"></a>
All instructions to build, deploy and test ArmoniK software on Linux are described in [ArmoniK deployment](./infrastructure/README.md)
<a href="https://github.com/aneoconsulting/ArmoniK.Samples/blob/main/README.md" target="_blank">Hello, world!</a>

# How to run ArmoniK.Samples <a name="how-to-run-armonik.samples"></a>
Instructions to run ArmoniK.Samples are described in [Run Samples](https://github.com/aneoconsulting/ArmoniK.Samples/blob/main/README.md)
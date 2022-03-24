# **ArmoniK** developer documentation

_ArmoniK_ is a high throughput compute grid project using Kubernetes. 

The project provides a reference architecture that can be used to build and adapt a modern high throughput compute
solution on-premise or using Cloud services, allowing users to submit high volumes of short and long-running tasks
and scaling environments dynamically.

**Warning**: This project is an Open Source ([Apache 2.0 License](https://github.com/aneoconsulting/ArmoniK/blob/main/LICENSE)).

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


## ArmoniK installation

Informations on how to install ArmoniK can be found [**here**](articles/intro.md)

[a comment]::

[Refer to http://daringfireball.net/projects/markdown/ for how to write markdown files.]::

[Add images to the *images* folder if the file is referencing an image.]::
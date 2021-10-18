# Table of contents
1. [Armonik](#armonik)
   1. [When should I use Armonik](#when-should-i-use-armonik)
   2. [When should I not use Armonik](#when-should-i-not-use-armonik)
2. [Software prerequisites](#software-prerequisites)
3. [Armonik software on-premise](#armonik-software-on-premise)
      1. [On Linux](#on-linux)
      2. [On Windows](#on-windows)
      3. [On Windows without Docker-Desktop](#on-windows-no-docker-desktop)
4. [Armonik software on cloud](#armonik-software-on-cloud)
   1. [Amazon Web Services (AWS)](#amazon-web-services)

# Armonik <a name="Armonik"></a>
<em>Armonik</em> is a high throughput compute grid project using Kubernetes. 
The project provides a reference architecture that can be used to build and adapt a modern high throughput compute
solution on-premise or using Cloud services, allowing users to submit high volumes of short and long running tasks
and scaling environments dynamically.

**Warning**: This project is an Open Source (Apache 2.0 License).

## When should I use Armonik <a name="when-should-i-use-armonik"></a>
Armonik should be used when the following criteria are meet:
1. A high task throughput is required (from 250 to 10,000+ tasks per second).
2. The tasks are loosely coupled.
3. Variable workloads (tasks with heterogeneous execution times) are expected and the solution needs to 
   dynamically scale with the load.

## When should I not use Armonik <a name="when-should-i-not-use-armonik"></a>
Armonik might not be the best choice if :
1. The required task throughput is below 250 tasks per second.
2. The tasks are tightly coupled, or use MPI.
3. The tasks uses third party licensed software.

# Software prerequisites <a name="software-prerequisites"></a>
The following resources should be installed upon you local machine :

* docker version > 1.19

* kubectl version > 1.19

* python > 3.7

* [virtualenv](https://pypi.org/project/virtualenv/)

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

* [helm](https://helm.sh/docs/intro/install/) version > 3

* [JQ](https://stedolan.github.io/jq/)

* [dotnet 5.0+](https://docs.microsoft.com/en-us/dotnet/core/install/)

# Armonik software on-premise <a name="armonik-software-on-premise"></a>
## On Linux <a name="on-linux"></a>
All instructions to build, deploy and test Armonik software on Linux are described in [Armonik on Linux](./README.ON-PREMISE-LINUX.md)

## On Windows <a name="on-windows"></a>
All instructions to build, deploy and test Armonik software on Windows are described in [Armonik on Windows](./README.ON-PREMISE-WINDOWS.md)

## On Windows without Docker-Desktop <a name="on-windows-no-docker-desktop"></a>
All instructions to build, deploy and test Armonik software on Windows without Docker-Desktop are described in [Armonik on Windows without Docker-Desktop](./README.ON-PREMISE-WINDOWS-NO-DOCKER-DESKTOP.md)



# Armonik software on cloud <a name="armonik-software-on-cloud"></a>
## Amazon Web Services (AWS) <a name="amazon-web-services"></a>
All instructions to build, deploy and test Armonik software are described in [Armonik on AWS cloud](./README.ON-AWS-CLOUD.md)
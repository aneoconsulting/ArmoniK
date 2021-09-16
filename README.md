# Table of contents
1. [Armonik](#armonik)
   1. [When should I use Armonik](#when-should-i-use-armonik)
   2. [Python environment](#python-environement)
2. [Getting started](#getteing-started)
   1. [Software prerequisites](#software-prerequisites)
   2. [Software prerequisites](#software-prerequisites)
3. [Armonik software on-premise](#armonik-software-on-premise)
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

## When should I use Armonik <a name="when-should-i-not-use-armonik"></a>
Armonik might not be the best choice if :
1. The required task throughput is below 250 tasks per second.
2. The tasks are tightly coupled, or use MPI.
3. The tasks uses third party licensed software.

# Getting started <a name="getting-started"></a>
## Software prerequisites <a name="software-prerequisites"></a>
The following resources should be installed upon you local machine :

* docker version > 1.19

* kubectl version > 1.19

* python > 3.7

* [virtualenv](https://pypi.org/project/virtualenv/)

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

* [helm](https://helm.sh/docs/intro/install/) version > 3

* [JQ](https://stedolan.github.io/jq/)

* [dotnet 5.0+](https://docs.microsoft.com/en-us/dotnet/core/install/)

## Python environment <a name="python-environment"></a>
The current release of Armonik requires python3 in the PATH of your system, and the documentation assumes the use of *virtualenv*. 

Set up this as follows (for example python3.7):
```bash
virtualenv --python=python3.7 venv
```

When successful :
```bash
created virtual environment CPython3.7.10.final.0-64 in 1329ms
  creator CPython3Posix(dest=<project_roor>/venv, clear=False, no_vcs_ignore=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/Users/user/Library/Application Support/virtualenv)
    added seed packages: pip==21.0.1, setuptools==54.1.2, wheel==0.36.2
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator
```

Check you have the correct version of python (`3.7.x`), with a path rooted on `<project_root>`, 
then start the environment:
```
source ./venv/bin/activate
```

Check the python version as follows:
```bash
$ which python
<project_root>/venv/bin/python
$ python -V
Python 3.7.10
```

# Armonik software on-premise <a name="armonik-software-on-premise"></a>
All instructions to build, deploy and test Armonik software are described in [Armonik on-premise](./README.ON-PREMISE.md)

# Armonik software on cloud <a name="armonik-software-on-cloud"></a>
All instructions to build, deploy and test Armonik software are described in [Armonik on-premise](./README.ON-CLOUD.md)

## Amazon Web Services (AWS) <a name="amazon-web-services"></a>
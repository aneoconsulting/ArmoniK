# Table of contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Install Kubernetes](#install-kubernetes)
- [Set environment variables](#set-environment-variables)
- [Deploy](#deploy)
    - [Kubernetes namespace](#kubernetes-namespace)
    - [KEDA](#keda)
    - [Storage](#storage)
    - [Monitoring](#monitoring)
    - [ArmoniK](#armonik)
- [Script bash all-in-one](#script-bash-all-in-one)
- [Quick tests](#quick-tests)
    - [Seq webserver](#seq-webserver)
    - [Tests](#tests)
- [Clean-up](#clean-up)

# Introduction

Hereafter, You have instructions to deploy ArmoniK on dev/test environment upon your local machine.

The infrastructure is composed of:

* [KEDA](https://keda.sh/)
* Storage:
    * ActiveMQ
    * MongoDB
    * Redis
* Monitoring:
    * Fluent-bit
    * Grafana
    * Metrics exporter
    * Prometheus
    * Prometheus Adapter
    * Seq server for structured log data of ArmoniK
* ArmoniK:
    * Control plane
    * Compute plane:
        * polling agent
        * workers

# Prerequisites

The following software or tool should be installed upon your local Linux machine:

* If You have Windows machine, You can install [WSL 2](docs/wsl2.md)
* [Docker](https://docs.docker.com/engine/install/)
* [GNU make](https://www.gnu.org/software/make/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [.NET](https://docs.microsoft.com/en-us/dotnet/core/install/linux)

# Install Kubernetes

You must have a Kubernetes on your local machine to install ArmoniK. If not, You can follow instructions in one of the
following documentation [Install Kubernetes on dev/test local machine](docs/k3s.md).

# Set environment variables

From the **root** of the repository, position yourself in directory `infrastructure/quick-deploy/localhost`.

```bash
cd infrastructure/quick-deploy/localhost
```

You need to set a list of environment variables [envvars.sh](envvars.sh) :

```bash
source envvars.sh
```

**or:**

```bash
export ARMONIK_KUBERNETES_NAMESPACE="armonik"
export ARMONIK_SHARED_HOST_PATH="${HOME}/data"
export ARMONIK_FILE_STORAGE_FILE="HostPath"
export ARMONIK_FILE_SERVER_IP=""
export KEDA_KUBERNETES_NAMESPACE="default"
```

where:

- `ARMONIK_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for ArmoniK
- `ARMONIK_SHARED_HOST_PATH`: is the filesystem on your local machine shared with workers of ArmoniK
- `ARMONIK_FILE_STORAGE_FILE`: is the type of the filesystem which can be one of `HostPath` or `NFS`
- `ARMONIK_FILE_SERVER_IP`: is the IP of the network filesystem if `ARMONIK_SHARED_HOST_PATH=NFS`
- `KEDA_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for [KEDA](https://keda.sh/)

# Deploy

**First**, You must create the `host_path="${HOME}/data"` directory which will be shared with ArmoniK worker pods (
see [storage/parameters.tfvars](storage/parameters.tfvars)):

```bash
mkdir -p "${ARMONIK_SHARED_HOST_PATH}"
```

## Kubernetes namespace

You create a Kubernetes namespace for ArmoniK and another for [KEDA](https://keda.sh/) with the names set in the environment
variables`ARMONIK_KUBERNETES_NAMESPACE` and `KEDA_KUBERNETES_NAMESPACE`:

```bash
make create-namespace
```

## KEDA

The parameters of KEDA are defined in [keda/parameters.tfvars](keda/parameters.tfvars).

Execute the following command to install KEDA:

```bash
make deploy-keda
```

The Keda deployment generates an output file `keda/generated/keda-output.json`.

**NOTE:** Please note that KEDA must be deployed only once on the same Kubernetes cluster.

## Storage

You need to create storage for ArmoniK which are:

* ActiveMQ broker
* MongoDB
* Redis

The parameters of each storage are defined in [storage/parameters.tfvars](storage/parameters.tfvars).

Execute the following command to create the storage:

```bash
make deploy-storage
```

The storage deployment generates an output file `storage/generated/storage-output.json` which contains information
needed for ArmoniK.

## Monitoring

You deploy the following resources for monitoring ArmoniK :

* Seq to collect the ArmoniK application logs
* Grafana
* Prometheus

The parameters of each monitoring resources are defined in [monitoring/parameters.tfvars](monitoring/parameters.tfvars).

Execute the following command to create the monitoring tools:

```bash
make deploy-monitoring
```

**or:**

```bash
make deploy-monitoring STORAGE_PARAMETERS_FILE=<path-to-storage-parameters>
```

where:

- `<path-to-storage-parameters>` is the **absolute** path to file `storage/generated/storage-output.json` containing the
  information about the storage previously created.

The monitoring deployment generates an output file `monitoring/generated/monitoring-output.json` which contains
information needed for ArmoniK.

## ArmoniK

After deploying the storage and monitoring tools, You can install ArmoniK. The installation deploys:

* ArmoniK control plane
* ArmoniK compute plane

The parameters of ArmoniK are defined in [armonik/parameters.tfvars](armonik/parameters.tfvars).

Execute the following command to deploy ArmoniK:

```bash
make deploy-armonik
```

**or:**

```bash
make deploy-armonik \
  STORAGE_PARAMETERS_FILE=<path-to-storage-parameters> \
  MONITORING_PARAMETERS_FILE=<path-to-monitoring-parameters>
```

where:

- `<path-to-storage-parameters>` is the **absolute** path to file `storage/generated/storage-output.json`
- `<path-to-monitoring-parameters>` is the **absolute** path to file `monitoring/generated/monitoring-output.json`

These files are input information for ArmoniK about storage and monitoring tools previously created.

The ArmoniK deployment generates an output file `armonik/generated/armonik-output.json` which contains the endpoint URL
of ArmoniK control plane.

### All-in-one deploy

All commands described above can be executed with one command. To deploy infrastructure and ArmoniK in all-in-one
command, You execute:

```bash
make deploy-all
```

# Script bash all-in-one

In addition to above instructions explaining how to deploy ArmoniK and its needed resources, You can use a script
bash [deploy-dev-test-infra.sh](../../utils/scripts/deploy-dev-test-infra.sh) to automate the deployment on your local
machine.

You have a PowerShell script [armonik_dev_environement.ps1](../../utils/scripts/armonik_dev_environment.ps1) too for
WSL2 machine that allows You to install the prerequisites and ArmoniK.

You can find the usage of the script Bash in [Script bash all-in-one](../../docs/all-in-one-deploy.md) and the usage of
the script PowerShell in [Script PowerShell all-in-one](../../docs/all-in-one-deploy-powershell.md).

# Quick tests

## Seq webserver

After the deployment, connect to the Seq webserver by using `seq.web_url` retrieved from the Terraform
outputs `monitoring/generated/monitoring-output.json`, example:

```bash
http://192.168.1.13:8080
```

or:

```bash
http://localhost:8080
```

where `Username: admin` and `Password: admin`:

![](images/seq_auth.png)

## Tests

### Scripts of tests

You have three scripts for testing ArmoniK :

* [tools/tests/symphony_like.sh](../../../tools/tests/symphony_like.sh)
* [tools/tests/datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh)
* [tools/tests/symphony_endToendTests.sh](../../../tools/tests/symphony_endToendTests.sh).

The following commands in these scripts allow to retrieve the endpoint URL of ArmoniK control plane:

```bash
export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
```

or You can replace them by the `armonik.control_plane_url` retrieved from Terraform
outputs `armonik/generated/armonik-output.json`, example:

```bash
export Grpc__Endpoint=http://192.168.1.13:5001
```

### Launch tests

Before executing the tests, You must download source codes of Samples from the **root** repository:

```bash
git submodule update --init --recursive
```

**and:**

```bash
git clone https://github.com/aneoconsulting/ArmoniK.Extensions.Csharp.git source/ArmoniK.Extensions.Csharp
```

**then:**

- Execute [tools/tests/symphony_like.sh](../../../tools/tests/symphony_like.sh) from the **root** repository:
  ```bash
  tools/tests/symphony_like.sh
  ```

- Execute [tools/tests/datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh) from the **root** repository:
  ```bash
  tools/tests/datasynapse_like.sh
  ```

- Execute [tools/tests/symphony_endToendTests.sh](../../../tools/tests/symphony_endToendTests.sh) from the **root**
  repository:
  ```bash
  tools/tests/symphony_endToendTests.sh
  ```

You can follow logs on Seq webserver:

![](images/seq.png)

# Clean-up

To delete all resources created in Kubernetes, You can execute the following all-in-one command:

```bash
make destroy-all
```

or execute the following commands in this order:

```bash
make destroy-armonik 
make destroy-monitoring 
make destroy-storage 
```

To clean-up and delete all generated files, You execute:

```bash
make clean-all
```

or:

```bash
make clean-armonik 
make clean-monitoring 
make clean-aws-storage 
``` 

### [Return to the infrastructure main page](../../README.md)

### [Return to the project main page](../../../README.md)




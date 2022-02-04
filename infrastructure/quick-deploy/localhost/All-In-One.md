# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Set environment variables](#set-environment-variables)
- [Prepare Kubernetes](#prepare-kubernetes)
    - [Install K3s](#install-k3s)
- [Deploy Storage and ArmoniK in one command](#deploy-storage-and-armonik-in-one-command)
    - [Show usage of script](#show-usage-of-script)
    - [All in one command](#all-in-one-command)
- [Quick tests](#quick-tests)
    - [Seq webserver](#seq-webserver)
    - [Tests](#tests)
- [Clean-up](#clean-up)
    - [Return to the main page](#return-to-the-main-page)

# Introduction

Hereafter, You have instructions to do to deploy ArmoniK on dev/test environment upon your local machine with a simple
deploy script

The infrastructure is composed of:

* Storage:
    * ActiveMQ
    * MongoDB
    * Redis
* Monitoring:
    * Seq server for structured log data of ArmoniK.
* ArmoniK:
    * Control plane
    * Compute plane: polling agent and workers

# Prerequisites

The following software or tool should be installed upon your local Linux machine:

* If You have Windows machine, You have to install [WSL 2](../../kubernetes/onpremise/localhost/wsl2.md)
* [Docker](https://docs.docker.com/engine/install/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

# Set environment variables

You have two list of environment variables to set upon your local machine:

* environment variables for storage [envvars-storage.sh](../../utils/scripts/envvars-storage.sh)
* environment variables for storage [envvars-monitoring.sh](../../utils/scripts/envvars-monitoring.sh)
* environment variables for ArmoniK [envvars-armonik.sh](../../utils/scripts/envvars-armonik.sh)

**Warning:** You can edit or copy these two files and modify values of the environment variables as You want.

Form the **root** of the repository, source the two list of environment variables:

```bash
source infrastructure/utils/scripts/envvars-storage.sh
source infrastructure/utils/scripts/envvars-monitoring.sh
source infrastructure/utils/scripts/envvars-armonik.sh
```

# Prepare Kubernetes

## Install K3s

To install [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/), execute the following command:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
```

# Deploy Storage and ArmoniK in one command

First, You must create the `host_path=/data` directory that will be shared with ArmoniK worker pods:

```bash
sudo mkdir -p /data
sudo chown -R $USER:$USER /data
```

From the **root** of the repository, position yourself in directory:

## Show usage of script

Execute the script to see the usage command :

```bash
infrastructure/utils/scripts/deploy-dev-test-infra.sh -h
```

the output will show something like :

```
Usage: infrastructure/utils/scripts/deploy-dev-test-infra.sh [option...]

   -m, --mode <Possible options below>
  Where --mode should be :
        destroy-all         : To destroy all storage and armonik in the same command
        destroy-armonik     : To destroy Armonik deployment only
        destroy-storage     : To destroy storage deployment only
        deploy-storage      : To deploy Storage independently on master machine. Available (Cluster or single node)
        deploy-armonik      : To deploy armonik
        deploy-all          : To deploy both Storage and Armonik
        redeploy-storage    : To REdeploy storage
        redeploy-armonik    : To REdeploy armonik
        redeploy-all        : To REdeploy both storage and armonik

   -ip, --nfs-server-ip <SERVER_NFS_IP>

   -s, --shared-storage-type <SHARED_STORAGE_TYPE>

  Where --shared-storage-type should be :
        HostPath            : Use in localhost
        NFS                 : Use a NFS server
        AWS_EBS             : Use an AWS Elastic Block Store

   -env, --environment <COMPUTE_ENVIRONMENT>
  Where --mode should be :
        onpremise           : ArmoniK is deployed on localhost or onpremise cluster
        aws                 : ArmoniK is deployed on AWS cloud
```

## All in one command

Now you can choose options you want to deploy all (storage and armonik) or only one of them or redeploy all see below
the serie of exemples :

To deploy for the first time :

```bash
#To deploy for the first time :
infrastructure/utils/scripts/deploy-dev-test-infra.sh -m deploy-all
```

To deploy for the first time only storage :

```bash
#To deploy for the first time only storage :
infrastructure/utils/scripts/deploy-dev-test-infra.sh -m deploy-storage
```

To deploy for the first time only armonik :

```bash
#To deploy for the first time only armonik :
infrastructure/utils/scripts/deploy-dev-test-infra.sh -m deploy-armonik
```

To RE deploy all of them (Storage and Armonik) :

```bash
#To RE deploy all of them (Storage and Armonik) :
infrastructure/utils/scripts/deploy-dev-test-infra.sh -m redeploy-all
```

And so on :

# Quick tests

## Seq webserver

After the deployment, connect to the Seq webserver by using `seq_web_url`, retrieved from the Terraform outputs,
example:

```bash
http://192.168.1.13:8080
```

or

```bash
http://localhost:8080
```

where `Username: admin` and `Password: admin`:

![](images/seq_auth.png)

## Tests

You have two scripts for testing ArmoniK [symphony_like.sh](../../../tools/tests/symphony_like.sh)
and [datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh). The following commands in these scripts allow to
retrieve the endpoint URL of ArmoniK control plane:

```bash
export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
```

or You can replace them by the `armonik_control_plane_url` retrieved from Terraform outputs, example:

```bash
export Grpc__Endpoint=http://192.168.1.13:5001
```

Execute [tools/tests/symphony_like.sh](../../../tools/tests/symphony_like.sh) from the **root** repository:

```bash
tools/tests/symphony_like.sh
```

Execute [tools/tests/datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh) from the **root** repository:

```bash
tools/tests/datasynapse_like.sh
```

Execute [tools/tests/symphony_endToendTests.sh](../../../tools/tests/symphony_endToendTests.sh) from the **root**
repository:

```bash
tools/tests/symphony_endToendTests.sh
```

You can follow logs on Seq webserver:

![](images/seq.png)

# Clean-up

**If you want** to delete all resources, execute the command:

```bash
#To destroy all of them (Storage and Armonik) :
infrastructure/utils/scripts/deploy-dev-test-infra.sh -m destroy-all
```

**If you want** to uninstall K3s, execute the command:

```bash
/usr/local/bin/k3s-uninstall.sh
```

### [Return to the main page](../../README.md)

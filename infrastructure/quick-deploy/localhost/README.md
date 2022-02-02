# Table of contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Set environment variables](#set-environment-variables)
4. [Prepare Kubernetes](#prepare-kubernetes)
    1. [Install K3s](#install-k3s)
    2. [Create namespaces and secrets](#create-namespaces-and-secrets)
5. [Prepare input parameters](#prepare-input-parameters)
6. [Deploy ArmoniK](#deploy-armonik)
7. [Quick tests](#quick-tests)
8. [Clean-up](#clean-up)

# Introduction

Hereafter, You have instructions to deploy ArmoniK on dev/test environment upon your local machine.

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

* If You have Windows machine, You can install [WSL 2](../../kubernetes/onpremise/localhost/wsl2.md)
* [Docker](https://docs.docker.com/engine/install/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

# Set environment variables

You have two list of environment variables to set upon your local machine:

* environment variables for storage [envvars-storage.conf](../../utils/envvars-storage.conf)
* environment variables for ArmoniK [envvars-armonik.conf](../../utils/envvars-armonik.conf)

**Warning:** You can edit or copy these two files and modify values of the environment variables as You want.

Form the **root** of the repository, source the two list of environment variables:

```bash
source infrastructure/utils/envvars-storage.conf
source infrastructure/utils/envvars-armonik.conf
```

# Prepare Kubernetes

## Install K3s

To install [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/), execute the following command:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
```

## Create namespaces and secrets

The script [init_kube.sh](../../../tools/install/init_kube.sh) allows to prepare your Kubernetes before deploying
ArmoniK. It contains a list of commands to create:

* Kubernetes namespaces for:
    * Storage
    * Monitoring
    * ArmoniK
* Kubernetes secrets for:
    * ActiveMQ
    * MongoDB
    * Redis

Form the **root** of the repository, execute the script `init_kube.sh`:

```bash
tools/install/init_kube.sh
```

# Prepare input parameters

Before deploying ArmoniK on your local machine, You have to prepare Terraform input parameters. The list of required
parameters are defined in [parameters.tfvars](parameters.tfvars), that You can edit or copy and modify the values of
each parameter. This parameter file contains four components:

* Logging level:
    ```terraform
    logging_level = "Information"
    ```

* Host path shared between ArmoniK worker pods and your local machine:
    ```terraform
    host_path = "/data"
    ```
* Parameters of ArmoniK control plane:

    ```terraform
    control_plane = {
      replicas           = 1
      image              = "dockerhubaneo/armonik_control"
      tag                = "0.4.0"
      image_pull_policy  = "IfNotPresent"
      port               = 5001
      limits             = {
        cpu    = "1000m"
        memory = "1024Mi"
      }
      requests           = {
        cpu    = "100m"
        memory = "128Mi"
      }
      image_pull_secrets = ""
   }
   ```

* Parameters of ArmoniK compute plane:

  ```terraform
  compute_plane = {
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    # number of queues according to priority of tasks
    max_priority                     = 1
    image_pull_secrets               = ""
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.4.0"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "100m"
        memory = "128Mi"
      }
      requests          = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        port              = 80
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.1.2-SNAPSHOT.4.cfda5d1"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "920m"
          memory = "2048Mi"
        }
        requests          = {
          cpu    = "50m"
          memory = "100Mi"
        }
      }
    ]
  }
  ```

# Deploy ArmoniK

First, You must create the `host_path=/data` directory that will be shared with ArmoniK worker pods:

```bash
sudo mkdir -p /data
sudo chown -R $USER:$USER /data
```

From the **root** of the repository, position yourself in directory:

```bash
cd infrastructure/quick-deploy/localhost
````

and execute:

```bash
make all PARAMETERS_FILE=parameters.tfvars 
```

or:

```bash
make all
```

After the deployment, an output file `generated/output.json` is generated containing the list of created resources:

```terraform
armonik_deployment = {
  "activemq"                  = {
    "host" = "10.43.239.76"
    "port" = "5672"
    "url"  = "amqp://10.43.239.76:5672"
  }
  "armonik_control_plane_url" = "http://192.168.1.13:5001"
  "mongodb"                   = {
    "host" = "10.43.245.249"
    "port" = "27017"
    "url"  = "mongodb://10.43.245.249:27017"
  }
  "redis"                     = {
    "host" = "10.43.116.202"
    "port" = "6379"
    "url"  = "10.43.116.202:6379"
  }
  "seq_web_url"               = "http://192.168.1.13:8080"
}
```

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

Execute [symphony_like.sh](../../../tools/tests/symphony_like.sh) from the **root** repository:

```bash
tools/tests/symphony_like.sh 
```

Execute [datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh) from the **root** repository:

```bash
tools/tests/datasynapse_like.sh
```

You can follow logs on Seq webserver:

![](images/seq.png)

# Clean-up

**If you want** to delete all resources, execute the command:

```bash
make destroy PARAMETERS_FILE=parameters.tfvars 
```

or:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```

**If you want** to uninstall K3s, execute the command:

```bash
/usr/local/bin/k3s-uninstall.sh
```

### [Return to the main page](../../README.md)




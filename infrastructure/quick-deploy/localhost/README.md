# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Install Kubernetes](#install-kubernetes)
- [Prepare input parameters (Optional)](#prepare-input-parameters-optional)
- [Deploy ArmoniK](#deploy-armonik)
    - [Deploy all-in-one](#deploy-all-in-one)
    - [Deploy step-by-step](#deploy-step-by-step)
- [Quick tests](#quick-tests)
    - [Seq webserver](#seq-webserver)
    - [Tests](#tests)
    - [Return to the main page](#return-to-the-main-page)

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

# Install Kubernetes

You must have a Kubernetes to install ArmoniK. If not, You can follow instructions in one of the following
documentation:

* [Install Kubernetes on dev/test local machine](../../kubernetes/onpremise/localhost/README.md)
* [Install Kubernetes on onpremise cluster](../../kubernetes/onpremise/cluster/README.md)
* [Install AWS EKS](../../kubernetes/aws/README.md)

# Prepare input parameters (Optional)

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

**First**, You must create the `host_path=/data` directory that will be shared with ArmoniK worker pods:

```bash
sudo mkdir -p /data
sudo chown -R $USER:$USER /data
```

## Deploy all-in-one

This method of deployment is interesting when all resources are deployed in the same Kubernetes.

### 1. Set environment variables

You have three list of environment variables to set upon your local machine:

* environment variables for storage [envvars-storage.conf](../../utils/envvars-storage.conf)
* environment variables for monitoring [envvars-monitoring.conf](../../utils/envvars-monitoring.conf)
* environment variables for ArmoniK [envvars-armonik.conf](../../utils/envvars-armonik.conf)

**Warning:** You can edit or copy these files and modify values of the environment variables as You want.

Form the **root** of the repository, source the two list of environment variables:

```bash
source infrastructure/utils/envvars-storage.conf
source infrastructure/utils/envvars-monitoring.conf
source infrastructure/utils/envvars-armonik.conf
```

### 2. Create Kubernetes namespaces and secrets

The scripts [init-kube-storage.sh](../../utils/scripts/init-kube-storage.sh)
, [init-kube-monitoring.sh](../../utils/scripts/init-kube-monitoring.sh)
and [init-kube-armonik.sh](../../utils/scripts/init-kube-armonik.sh) allow to prepare your Kubernetes before deploying
ArmoniK. It contains a list of commands to create:

* Kubernetes namespaces for:
    * Storage
    * Monitoring
    * ArmoniK
* Kubernetes secrets for:
    * ActiveMQ
    * MongoDB
    * Redis

Form the **root** of the repository, execute the scripts:

```bash
infrastructure/utils/scripts/init-kube-storage.sh
infrastructure/utils/scripts/init-kube-monitoring.sh
infrastructure/utils/scripts/init-kube-armonik.sh
```

### 3. Deploy

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
armonik_deployment   = tomap({
  "armonik_control_plane_url" = "http://192.168.1.13:5001"
  "seq_web_url"               = "http://192.168.1.13:8080"
})
seq_endpoints        = tomap({
  "host"    = "192.168.1.13"
  "port"    = "5341"
  "url"     = "http://192.168.1.13:5341"
  "web_url" = "http://192.168.1.13:8080"
})
storage_endpoint_url = tomap({
  "activemq" = {
    "host" = "10.43.163.90"
    "port" = "5672"
    "url"  = "amqp://10.43.163.90:5672"
  }
  "mongodb"  = {
    "host" = "10.43.238.208"
    "port" = "27017"
    "url"  = "mongodb://10.43.238.208:27017"
  }
  "redis"    = {
    "host" = "10.43.133.187"
    "port" = "6379"
    "url"  = "10.43.133.187:6379"
  }
})
```

### 4. Clean-up

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

## Deploy step-by-step

This method of deployment is interesting for the case where each of storage, monitoring and ArmoniK are deployed in
different infrastructure environments.

### Deploy monitoring

#### 1. Set environment variables

You have a list of environment variables [envvars-monitoring.conf](../../utils/envvars-monitoring.conf) to set upon your
local machine. You can edit or copy the file and modify values of the environment variables as You want.

Form the **root** of the repository, source the list of environment variables:

```bash
source infrastructure/utils/envvars-monitoring.conf
```

#### 2. Create Kubernetes namespaces and secrets

The script [init-kube-monitoring.sh](../../utils/scripts/init-kube-monitoring.sh) allows to prepare your Kubernetes
before deploying monitoring tools.

Form the **root** of the repository, execute the script:

```bash
infrastructure/utils/scripts/init-kube-monitoring.sh
```

#### 3. Deploy

From the **root** of the repository, position yourself in directory:

```bash
cd infrastructure/quick-deploy/localhost
````

and execute:

```bash
make deploy-monitoring
```

After the deployment, an output file `generated/monitoring-output.json` is generated containing the list of created
resources:

```json
{
  "seq_endpoints": {
    "host": "192.168.1.13",
    "port": "5341",
    "url": "http://192.168.1.13:5341",
    "web_url": "http://192.168.1.13:8080"
  }
}
```

#### 4. Clean-up

**If you want** to delete all monitoring resources, execute the command:

```bash
make destroy-monitoring
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```

### Deploy storage

### 1. Set environment variables

You have a list of environment variables [envvars-storage.conf](../../utils/envvars-storage.conf) to set upon your local
machine. You can edit or copy the file and modify values of the environment variables as You want.

Form the **root** of the repository, source the list of environment variables:

```bash
source infrastructure/utils/envvars-storage.conf
```

### 2. Create Kubernetes namespaces and secrets

The script [init-kube-storage.sh](../../utils/scripts/init-kube-storage.sh) allows to prepare your Kubernetes before
deploying Storage.

Form the **root** of the repository, execute the script:

```bash
infrastructure/utils/scripts/init-kube-storage.sh
```

### 3. Deploy

From the **root** of the repository, position yourself in directory:

```bash
cd infrastructure/quick-deploy/localhost
````

and execute:

```bash
make deploy-storage
```

After the deployment, an output file `generated/storage-output.json` is generated containing the list of created
resources:

```json
{
  "storage_endpoint_url": {
    "activemq": {
      "host": "10.43.57.240",
      "port": "5672",
      "url": "amqp://10.43.57.240:5672"
    },
    "mongodb": {
      "host": "10.43.142.93",
      "port": "27017",
      "url": "mongodb://10.43.142.93:27017"
    },
    "redis": {
      "host": "10.43.56.182",
      "port": "6379",
      "url": "10.43.56.182:6379"
    }
  }
}
```

### 4. Clean-up

**If you want** to delete storage resources, execute the command:

```bash
make destroy-storage
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```

### Deploy ArmoniK

### 1. Set environment variables

You have a list of environment variables [envvars-armonik.conf](../../utils/envvars-armonik.conf) to set upon your local
machine. You can edit or copy the file and modify values of the environment variables as You want.

Form the **root** of the repository, source the list of environment variables:

```bash
source infrastructure/utils/envvars-armonik.conf
```

### 2. Create Kubernetes namespaces and secrets

The script [init-kube-armonik.sh](../../utils/scripts/init-kube-armonik.sh) allows to prepare your Kubernetes before
deploying ArmoniK.

Form the **root** of the repository, execute the script:

```bash
infrastructure/utils/scripts/init-kube-armonik.sh
```

### 3. Deploy

From the **root** of the repository, position yourself in directory:

```bash
cd infrastructure/quick-deploy/localhost
````

and execute:

```bash
make deploy-armonik PARAMETERS_FILE=parameters.tfvars STORAGE_INPUT_FILE=<path-storage-endpoint-urls> MONITORING_INPUT_FILE=<path-monitoring-endpoint-urls>
```

where:

* `<path-storage-endpoint-urls>` is the file generated after the storage deployment
* `<path-monitoring-endpoint-urls>` is the file generated after the monitoring deployment

for example:

```bash
make deploy-armonik PARAMETERS_FILE=parameters.tfvars STORAGE_INPUT_FILE=generated/storage-output.json MONITORING_INPUT_FILE=generated/monitoring-output.json
```

or :

```bash
make deploy-armonik
```

After the deployment of ArmoniK, an output file `generated/armonik-output.json` is generated containing the list of
created resources:

```json
{
  "armonik_deployment": {
    "armonik_control_plane_url": "http://192.168.1.13:5001",
    "seq_web_url": "http://192.168.1.13:8080"
  }
}
```

### 4. Clean-up

**If you want** to delete ArmoniK resources, execute the command:

```bash
make destroy-armonik
```

**If you want** to delete Storage, Monitoring and ArmoniK resources, execute the command:

```bash
make destroy-all
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
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

You have three scripts for testing ArmoniK :

* [symphony_like.sh](../../../tools/tests/symphony_like.sh)
* [datasynapse_like.sh](../../../tools/tests/datasynapse_like.sh)
* [tools/tests/symphony_endToendTests.sh](../../../tools/tests/symphony_endToendTests.sh). T

The following commands in these scripts allow to retrieve the endpoint URL of ArmoniK control plane:

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

Execute [tools/tests/symphony_endToendTests.sh](../../../tools/tests/symphony_endToendTests.sh) from the **root**
repository:

```bash
tools/tests/symphony_endToendTests.sh
```

You can follow logs on Seq webserver:

![](images/seq.png)

### [Return to the Main page](../../README.md)




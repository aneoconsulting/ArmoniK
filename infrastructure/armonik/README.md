# Table of contents

1. [Introduction](#introduction)
2. [Prepare the configuration file](#prepare-the-configuration-file)
3. [Deploy](#deploy)
4. [Clean-up](#clean-up)

# Introduction

This project presents the instructions to deploy ArmoniK in Kubernetes.

# Prepare the configuration file

Before deploying the storages, you must fist prepare a configuration file containing a list of the parameters of the
storages to be created.

The configuration has six components:

1. Kubernetes namespace where ArmoniK's components will be created:

```terraform
namespace = "armonik"
```

2. Level of logging

```terraform
logging_level = "Information"
```

3. List of storage for each ArmoniK data:

```terraform
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  shared         = "HostPath"
  # Mandatory: If you want execute the HTC Mock sample, you must set this parameter to "Redis", otherwise let it to ""
  external       = "Redis"
}
```

`external` storage is a parameter to choose un external storage for data client. By default, it is set to empty
string `""`, but for **HTC Mock sample** you must set it to `"Redis"`.

4. List of endpoint urls and credentials for each needed storage:

```terraform
storage_endpoint_url = {
  mongodb  = {
    url    = "mongodb://192.168.1.13:27017"
    secret = ""
  }
  redis    = {
    url    = ""
    secret = ""
  }
  activemq = {
    host   = "192.168.1.13"
    port   = "5672"
    secret = "activemq-storage-secret"
  }
  shared   = {
    host   = ""
    secret = ""
    # Path to external shared storage from which worker containers upload .dll
    path   = "/data"
  }
  external = {
    url    = "192.168.1.13:6379"
    secret = "external-redis-storage-secret"
  }
}
```

5. Information for **ArmoniK control plane**:

```terraform
control_plane = {
  replicas          = 1
  image             = "dockerhubaneo/armonik_control"
  tag               = "0.0.6"
  image_pull_policy = "IfNotPresent"
  port              = 5001
}
```

6. Information for **ArmoniK compute plane** which is composed of a container of `polling agent` and container(s)
   of `worker(s)`:

```terraform
compute_plane = {
  # number of replicas for each deployment of compute plane
  replicas      = 1
  # number of queues according to priority of tasks
  max_priority  = 1
  # ArmoniK polling agent
  polling_agent = {
    image             = "dockerhubaneo/armonik_pollingagent"
    tag               = "0.0.6"
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
  worker        = [
    {
      name              = "worker"
      port              = 80
      # [Default]
      image             = "dockerhubaneo/armonik_worker_dll"
      # HTC Mock
      #image             = "dockerhubaneo/armonik_worker_htcmock"
      tag               = "0.0.6"
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

**warning:** You have an example of [configuration file](./parameters.tfvars). There is
also [parameters doc of ArmoniK deployment](../docs/deploy/deploy-config.md).

# Deploy

Execute the following command to deploy ArmoniK:

```bash
make all CONFIG_FILE=<Your configuration file> 
```

You can also execute one of the following commands if you want to reuse the default configuration file:

```bash
make all CONFIG_FILE=parameters.tfvars 
```

or:

```bash
make all
```

The command `make all` executes three commands in the following order that you can execute separately:

* `make init`
* `make plan CONFIG_FILE=<Your configuration file>`
* `make apply CONFIG_FILE=<Your configuration file>`

After the deployment you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_NAMESPACE
```

# Clean-up

**If you want** to delete all ArmoniK resources deployed as services in Kubernetes, execute the command:

```bash
make destroy CONFIG_FILE=<Your configuration file> 
```

or, if you have used the default configuration file:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```
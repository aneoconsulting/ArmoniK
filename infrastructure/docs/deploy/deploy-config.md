# Table of contents

1. [Introduction](#Introduction)
2. [Global parameters](#global-parameters)
3. [Seq](#seq)
4. [Storage](#storage)
5. [Storage endpoint urls](#storage-endpoint-urls)
6. [Control plane](#control-plane)
7. [Compute plane](#compute-plane)

# Introduction

The parameters in the configuration file to create ArmoniK resources.

# Global parameters

```terraform
namespace          = string
k8s_config_path    = string
k8s_config_context = string
logging_level      = string
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `namespace`           | Kubernetes namespace of ArmoniK resources, created during the [Create a namespace for ArmoniK](./onpremise.md) | string | `"armonik"` |
| `k8s_config_path`     | Path to the Kubernetes configuration file | string | `"~/.kube/config"` |
| `k8s_config_context`  | Configuration context of Kubernetes | string | `"default"` |
| `logging_level`  | Level of logging in ArmoniK | string | `"Information"` |

# Seq

[Seq](https://datalust.co/) is the intelligent search, analysis, and alerting server built specifically for modern
structured log data.

```terraform
seq = {
  replicas = number
  port     = [
    {
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }
  ]
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of Seq | number | `1` |
| `port` | List of ports and their names | list(object({})) | `[{name="ingestion", port=5341, target_port=5341, protocol="TCP"}, {name="web", port=8080, target_port=80, protocol="TCP"}]` |

# Storage

Needed storage for each ArmoniK data
type ([Allowed storage for ArmoniK](../../modules/needed-storage/storage_for_each_armonik_data.tf)).

```terraform
storage = {
  object         = string
  table          = string
  queue          = string
  lease_provider = string
  shared         = string
  external       = string
}
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `object` | Storage name for ArmoniK object data | string | `"MongoDB"` |
| `table` | Storage name for ArmoniK table data | string | `"MongoDB"` |
| `queue` | Storage name for ArmoniK queue data | string | `"Amqp"` |
| `lease_provider` | Storage name for ArmoniK lease provider data | string | `"MongoDB"` |
| `shared` | Shared storage name for ArmoniK worker containers | string | `"HostPath"` |
| `external` | Storage name for ArmoniK client data for HTC Mock sample  | string | `"Redis"` |

# Storage endpoint urls

The endpoint urls and credentials to needed storage by ArmoniK.

```terraform
storage_endpoint_url = {
  mongodb  = {
    url    = string
    secret = string
  }
  redis    = {
    url    = string
    secret = string
  }
  activemq = {
    host   = string
    port   = string
    secret = string
  }
  shared   = {
    host   = string
    secret = string
    path   = string
  }
  external = {
    url    = string
    secret = string
  }
}
```

#### **mongodb**

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `url` | Endpoint url to MongoDB | string | `"mongodb://192.168.1.13:27017"` |
| `secret` | Kubernetes secret for MongoDB client | string | `""` |

#### **redis**

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `url` | Endpoint url to Redis | string | `""` |
| `secret` | Kubernetes secret for Redis client | string | `""` |

#### **activemq**

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `host` | Host name of ActiveMQ server | string | `"192.168.1.13"` |
| `port` | Port of ActiveMQ server | string | `"5672"` |
| `secret` | Kubernetes secret for ActiveMQ client | string | `"activemq-storage-secret"` |

#### **shared**

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `host` | Host name of shared storage | string | `""` |
| `secret` | Connection string for shared storage | string | `""` |
| `path` | Path to external shared storage from which worker containers upload .dll | string | `"/data"` |

#### **external**

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `url` | Endpoint url to external cache, by default is Redis | string | `"192.168.1.13:6379"` |
| `secret` | Kubernetes secret for Redis client | string | `"external-redis-storage-secret"` |

# Control plane

Information about ArmoniK control plane to be created.

```terraform
control_plane = {
  replicas          = number
  image             = string
  tag               = string
  image_pull_policy = string
  port              = number
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas for control plane | number | `1` |
| `image` | Container image name of control plane | string | `"dockerhubaneo/armonik_control"` |
| `tag` | Tag of the container image of the control plan | string | `"0.0.6"` |
| `image_pull_policy` | Image pull policy for control plane container | string | `"IfNotPresent"` |
| `port` | Port of the control plane service | number | `5001` |

# Compute plane

Information about ArmoniK control plane to be created. It contains a container of polling agent and container(s) for
worker(s).

```terraform
compute_plane = {
  replicas      = number
  # number of queues according to priority of tasks
  max_priority  = number
  polling_agent = {
    image             = string
    tag               = string
    image_pull_policy = string
    limits            = {
      cpu    = string
      memory = string
    }
    requests          = {
      cpu    = string
      memory = string
    }
  }
  worker        = [
    {
      name              = string
      port              = number
      image             = string
      tag               = string
      image_pull_policy = string
      limits            = {
        cpu    = string
        memory = string
      }
      requests          = {
        cpu    = string
        memory = string
      }
    }
  ]
}
```

### ***compute_plane***

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas for compute plane | number | `1` |
| `max_priority` | Maximum number of priority for tasks. It defines the number of queues according to the priority too | number | `1` |

#### ***polling_agent***

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `image` | Docker image name of polling agent container in the compute plane | string | `"dockerhubaneo/armonik_pollingagent"` |
| `tag` | Tag of the docker image of polling agent container in the compute plane | string | `"0.0.6"` |
| `image_pull_policy` | Image pull policy for polling agent container in the compute plane | string | `"IfNotPresent"` |
| `limits` | Maximum amount of compute resources allowed in the polling agent container| object({}) | `limits = { cpu = "100m", memory = "128Mi" }`|
| `requests` | Minimum amount of compute resources allowed in the polling agent container | object({}) | `requests = { cpu = "100m", memory = "128Mi" }` |

#### ***worker***

`worker` parameter is a list of objects (`list(object({}))`) describing the attributes of each worker container in
compute plane, as follows:

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `name` | Name of the worker container in compute plane | string | `"worker"` |
| `port` | Port of the worker container in compute plane | number | `80` |
| `image` | Docker image name of the worker container in compute plane | string | `"dockerhubaneo/armonik_worker_dll"` |
| `tag` | Tag of docker image of the worker container in compute plane | string | `"0.0.6"` |
| `image_pull_policy` | Image pull policy for worker container in the compute plane | string | `"IfNotPresent"` |
| `limits` | Maximum amount of compute resources allowed in the worker container | object({}) | `limits = { cpu = "920m", memory = "3966Mi" }`|
| `requests` | Minimum amount of compute resources allowed in the worker container | object({}) | `requests = { cpu = "50m", memory = "3966Mi" }` |
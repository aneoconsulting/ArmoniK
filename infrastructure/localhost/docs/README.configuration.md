# Table of contents

1. [Global parameters](#global-parameters)
2. [MongoDB parameters](#mongodb-parameters)
3. [Redis parameters](#redis-parameters)
4. [ActiveMQ parameters](#activemq-parameters)
5. [Local shared storage parameters](#local-shared-storage-parameters)
6. [ArmoniK parameters](#armonik-parameters)

# Global parameters <a name="global-parameters"></a>

```terraform
namespace          = string
k8s_config_path    = string
k8s_config_context = string
max_priority       = number
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `namespace`           | Kubernetes namespace of ArmoniK resources, created during the [preparation of the Kubernetes](./README.kubernetes.md#create-a-namespace-for-armonik) | string | `"armonik"`        |
| `k8s_config_path`     | Path to the Kubernetes configuration file                                                                             | string | `"~/.kube/config"` |
| `k8s_config_context`  | Configuration context of Kubernetes                                                                                   | string | `"default"`        |
| `max_priority`        | Maximum number of priority for tasks. It defines the number of queues according to the priority too                   | number | `1`              |

# MongoDB parameters <a name="mongodb-parameters"></a>

[MongoDB](https://www.mongodb.com/) is an open source NoSQL database management program.

```terraform
mongodb = {
  replicas = number
  port     = number
}
```

| Parameter     | Description                           | Type   | Default |
|:--------------|:--------------------------------------|:-------|:--------|
| `replicas`    | Number of desired replicas of MongoDB | number | `1`     |
| `port`        | Port of MongoDB                       | number | `27017` |

# Redis parameters <a name="redis-parameters"></a>

[Redis](https://redis.io/) is an open source (BSD licensed), in-memory data structure store, used as a database, cache,
and message broker.

```terraform
redis = {
  replicas = number
  port     = number
  secret   = string
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of Redis | number | `1` |
| `port` | Port of Redis | number | `6379` |
|  `secret` | Kubernetes secret for Redis, created during the [preparation of the Kubernetes](./README.kubernetes.md#redis-storage-secret) based on TLS certificates | string | `"redis-storage-secret"` |

# ActiveMQ parameters <a name="activemq-parameters"></a>

[Apache ActiveMQ](https://activemq.apache.org/) is the most popular open source, multi-protocol, Java-based message
broker.

```terraform
activemq = {
  replicas = number
  port     = [
    {
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }
  ]
  secret   = string
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of ActiveMQ | number | `1` |
| `port` | List of ports and their names | list(object({})) | `[{ name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },{ name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },{ name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },{ name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },{ name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }]` |
| `secret` | Kubernetes secret for ActiveMQ, created during the [preparation of the Kubernetes](./README.kubernetes.md#activemq-storage-secret) | string | `"activemq-storage-secret"` |

# Local shared storage parameters <a name="local-shared-storage-parameters"></a>

A storage volume shared between the host (local machine) and pods. The shared volume mount points are, respectively, in
`host_path` in your local machine and in `target_path` in pods.

```terraform
local_shared_storage = {
  storage_class           = {
    name = string
  }
  persistent_volume       = {
    name      = string
    size      = string
    host_path = string
  }
  persistent_volume_claim = {
    name = string
    size = string
  }
}
```

### ***storage_class***

A StorageClass provides a way for administrators to describe the "classes" of storage they offer.

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `name` | Name of the storage class to be created | string | `nfs` |

### ***persistent_volume***

A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator or
dynamically provisioned using Storage Classes.

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `name` | Name of the persistent volume | string | `nfs-pv` |
| `size` | Storage size capacity in `Mi`, `Gi`, etc. | string | `"10Gi"` |
| `host_path` | Represents a directory on the host (local machine). Provisioned by a developer or tester | string | `"/data"` |

### ***persistent_volume_claim***

A Persistent Volume Claim (PVC) is a request for storage by a user. PVCs consume PV resources. Claims can request
specific size and access modes.

| Parameter | Description | Type | Default | 
|:----------|:------------|:-----|:--------| 
| `name` | Name of the persistent volume claim | string | `nfs-pvc` | 
| `size` | Minimum amount of storage size in `Mi`, `Gi`, etc. | string | `"2Gi"` |

# ArmoniK parameters <a name="armonik-parameters"></a>

ArmoniK components are composed of :

```terraform
armonik = {
  control_plane    = {
    replicas          = number
    image             = string
    tag               = string
    image_pull_policy = string
    port              = number
  }
  compute_plane    = {
    replicas      = number
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
    compute       = [
      {
        name              = string
        port              = numebr
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
  storage_services = {
    object_storage_type         = string
    table_storage_type          = string
    queue_storage_type          = string
    lease_provider_storage_type = string
    shared_storage_target_path  = string
  }
}
```

### ***control_plane***

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas for control plane | number | `1` |
| `image` | Container image name of control plane | string | `"dockerhubaneo/armonik_control"` |
| `tag` | Tag of the container image of the control plan | string | `"dev-6330"` |
| `image_pull_policy` | Image pull policy for control plane container | string | `"IfNotPresent"` |
| `port` | Port of the control plane service | number | `5001` |

### ***compute_plane***

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas for compute plane | number | `1` |

#### ***polling_agent***

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `image` | Docker image name of polling agent container in the compute plane | string | `"dockerhubaneo/armonik_pollingagent"` |
| `tag` | Tag of the docker image of polling agent container in the compute plane | string | `"dev-6330"` |
| `image_pull_policy` | Image pull policy for polling agent container in the compute plane | string | `"IfNotPresent"` |
| `limits` | Maximum amount of compute resources allowed in the polling agent container| object({}) | `limits = { cpu = "100m", memory = "128Mi" }`|
| `requests` | Minimum amount of compute resources allowed in the polling agent container | object({}) | `requests = { cpu = "100m", memory = "128Mi" }` |

#### ***compute***

`compute` parameter is a list of objects (`list(object({}))`) describing the attributes of each compute container in
compute plane, as follows:

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `name` | Name of the compute container in compute plane | string | `"compute"` |
| `port` | Port of the compute container in compute plane | number | `80` |
| `image` | Docker image name of the compute container in compute plane | string | `"dockerhubaneo/armonik_compute"` |
| `tag` | Tag of docker image of the compute container in compute plane | string | `"dev-6330"` |
| `image_pull_policy` | Image pull policy for compute container in the compute plane | string | `"IfNotPresent"` |
| `limits` | Maximum amount of compute resources allowed in the compute container | object({}) | `limits = { cpu = "920m", memory = "3966Mi" }`|
| `requests` | Minimum amount of compute resources allowed in the compute container | object({}) | `requests = { cpu = "50m", memory = "3966Mi" }` |

### ***storage_services***

The different storage used by ArmoniK:

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `object_storage_type` | Type of the object storage | string | `"MongoDB"` |
| `table_storage_type` | Type of the table storage | string | `"MongoDB"` |
| `queue_storage_type` | Type of the queue storage | string | `"MongoDB"` |
| `lease_provider_storage_type` | Type of the lease provider storage | string | `"MongoDB"` |
| `shared_storage_target_path` | | string | `"/data"` |

The allowed types for each storage are as follows:

```terraform
storage = {
  allowed_object_storage         = [
    "MongoDB",
    "Redis"
  ]
  allowed_table_storage          = [
    "MongoDB"
  ]
  allowed_queue_storage          = [
    "MongoDB",
    "ActiveMQ"
  ]
  allowed_lease_provider_storage = [
    "MongoDB"
  ]
}
```
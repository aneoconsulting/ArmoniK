# Table of contents

1. [Introduction](#Introduction)
2. [Global parameters](#global-parameters)
3. [Storage](#storage)
4. [Secrets](#secrets)
5. [Parameters for each storage](#parameters-for-each-storage)

# Introduction

The parameters in the configuration file to create storage resources for ArmoniK.

# Global parameters

```terraform
namespace          = string
k8s_config_path    = string
k8s_config_context = string
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `namespace`           | Kubernetes namespace of ArmoniK storage resources, created during the [Create a namespace for ArmoniK storage](../../storage/onpremise/README.md) | string | `"armonik-storage"`        |
| `k8s_config_path`     | Path to the Kubernetes configuration file                                                                             | string | `"~/.kube/config"` |
| `k8s_config_context`  | Configuration context of Kubernetes                                                                                   | string | `"default"`        |

# Storage

The list of storage for each ArmoniK data
type ([Allowed storage for ArmoniK](../../modules/needed-storage/storage_for_each_armonik_data.tf)).

```terraform
storage = list(string)
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `storage` | List of storage to be deployed | list(string) | `["MongoDB", "Amqp"]` |

# Secrets

The Kubernetes secrets for each storage created during [Create Kubernetes secrets](../../storage/onpremise/README.md).

```terraform
storage_kubernetes_secrets = {
  mongodb  = ""
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
```

| Parameter             | Description | Type | Default |
|:----------------------|:------------|:-----|:--------|
| `mongodb` | Kubernetes secret for MongoDB | string | `""` |
| `redis` | Kubernetes secret for Redis | string | `"redis-storage-secret"` |
| `activemq` | Kubernetes secret for ActiveMQ | string | `"activemq-storage-secret"` |

# Parameters for each storage

The details of parameters of each storage to be deployed are defined [here](../../modules/storage/README.md).


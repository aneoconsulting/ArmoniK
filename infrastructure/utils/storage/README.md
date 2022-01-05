# Table of contents

1. [Introduction](#introduction)
2. [Allowed storage resources](#allowed-storage-resources)
3. [Storage deployment](#storage-deployment)
    1. [Onpremise storage](#onpremise-storage)

# Introduction

This project presents an example of source codes to create storage resources for ArmoniK.

# Allowed storage resources

To date, the storage resources allowed for each type of ArmoniK data are as follows:

```json
{
  "allowed_object_storage": [
    "MongoDB",
    "Redis"
  ],
  "allowed_table_storage": [
    "MongoDB"
  ],
  "allowed_queue_storage": [
    "MongoDB",
    "Amqp"
  ],
  "allowed_lease_provider_storage": [
    "MongoDB"
  ],
  "allowed_shared_storage": [
    "HostPath",
    "NFS"
  ],
  "allowed_external_storage": [
    "Redis"
  ]
}
```

# Storage deployment

## Onpremise storage

The storage resources will be created as **Kubernetes services**. Therefore, you must already have a Kubernetes already
installed.

> **_NOTE:_** If you do not have a Kubernetes already installed, you can use [Install Kubernetes docs](../../docs/deploy/onpremise.md#kubernetes) to install Kubernetes on a local machine or an onpremise cluster.

The source codes to create the needed storage resources for ArmoniK are defined in [Onpremise storage resources](onpremise/README.md).
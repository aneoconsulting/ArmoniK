# Table of contents

1. [Introduction](#introduction)
2. [Allowed storage resources](#allowed-storage-resources)
3. [Storage deployment](#storage-deployment)

# Introduction <a name="introduction"></a>

This project presents an example of source codes to create storage resources for ArmoniK.

The storage resources will be created as **Kubernetes services**. Therefore, you must already have a Kubernetes already
installed, if not you must install it by following, for example, [Install Kubernetes docs](../README.md#kubernetes).

# Allowed storage resources <a name="allowed-storage-resources"></a>

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
  "allowed_external_storage": [
    "Redis"
  ]
}
```

# Storage deployment 
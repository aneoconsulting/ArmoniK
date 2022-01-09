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

The configuration has three components:

1. Kubernetes namespace where the storage will be created:

```terraform
# Namespace of ArmoniK storage
namespace = "armonik"
```

2. List of storage to be created for each ArmoniK data:

```terraform
# Storage resources to be created
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  shared         = "HostPath"
  external       = ""
}
```

3. List of Kubernetes secrets of each storage to be created:

```terraform
# Kubernetes secrets for storage
storage_kubernetes_secrets = {
  mongodb  = ""
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
```

**warning:** You have an example of [configuration file](./parameters.tfvars). There is
also [parameters doc of storage deployment](../../docs/deploy/storage-deploy-config.md).

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
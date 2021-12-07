# Table of contents

1. [Software prerequisites](#software-prerequisites)
2. [Infrastructure source codes](#infrastructure-source-codes)
3. [Configuration file](#configuration-file)
    1. [List of resource parameters](#list-of-resource-parameters)
    2. [Example of configuration file](#example-of-configuration-file)
4. [Deployment](#deployment)

# Software prerequisites <a name="software-prerequisites"></a>

The following resources should be installed upon you local machine :

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) version > 1.0.0
* [JQ](https://stedolan.github.io/jq/)

# Infrastructure source codes <a name="nfrastructure-source-codes"></a>

The source codes of resources to be deployed are defined in the directory [deploy/](../deploy). They contain two main
types of resources:

* **Storage services**: ArmoniK needs a single or different types of storage to store its different
  data ([storage](../deploy/modules/storage)).
    * Object storage
    * Table
    * Queue
    * Lease provider
* **ArmoniK components**: are the components of the ArmoniK scheduler ([armonik](../deploy/modules/armonik)).
    * Control plane
    * Compute plane composed of polling agent and compute

For the storage, three types of storage will be created as services in the Kubernetes cluster:

* MongoDB
* Redis
* ActiveMQ
* Shared volume used as NFS

> **_NOTE:_**  The shared volume mount points are, respectively, in `host_path=/data` in your local machine and in
`target_path=/data` in pods. Of course, you can change the values of these parameters in the configuration file of the deployment with Terraform.

# Configuration file <a name="configuration-file"></a>

Terraform needs a configuration file containing the list of parameters to configure the resources to be created.

## List of resource parameters <a name="list-of-resource-parameters"></a>

The complete list of parameters and their types are defined in [List of parameters](../docs/README.configuration.md).

## Example of configuration file <a name="example-of-configuration-file"></a>

An example of a configuration file is given in [example-parameters.tfvars](../deploy/parameters.tfvars). You can make a
copy to the file and change the values of each resource parameter if needed. This file will be used as the input
for `make all`.

# Deployment <a name="deployment"></a>

To deploy ArmoniK components and the storage services:

1. in the directory [deploy/](../deploy):

```bash
cd ./deploy
```

2. execute this command to deploy ArmoniK:

```bash
make all CONFIG_FILE=<Your configuration file> 
```

such as `make all` executes three commands in this order:

* `make init`
* `make plan CONFIG_FILE=<Your configuration file>`
* `make apply CONFIG_FILE=<Your configuration file>`

After the deployment you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_NAMESPACE
```
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

An example of a configuration file is given in [parameters.tfvars](../deploy/parameters.tfvars). You can make a copy to
the file and change the values of each resource parameter if needed. This file will be used as the input for `make all`.

# Deployment <a name="deployment"></a>

To deploy ArmoniK components and the storage services:

1. position you in the directory [deploy/](../deploy):

    ```bash
    cd ./deploy
    ```

2. prepare a configuration file. You can reuse or modify the current [parameters.tfvars](../deploy/parameters.tfvars):

* Create a directory on your host (local machine), for example `/data`, and set the parameter `host_path=/data` in
  the `local_shared_storage.persistent_volume` component:

    ```terraform
    persistent_volume = {
      name      = "nfs-pv"
      size      = "5Gi"
      # Path of a directory in you local machine
      host_path = "/data"
    }
    ```

* The resources to be used for each type of ArmoniK storage `storage_services` must be well-defined, for example:

    ```terraform
    # Storage used by ArmoniK
    storage_services = {
     object_storage_type         = "MongoDB"
     table_storage_type          = "MongoDB"
     queue_storage_type          = "Amqp"
     lease_provider_storage_type = "MongoDB"
     # Path of a directory in a pod, which contains data shared between pods and your local machine
     shared_storage_target_path  = "/data"
    }
    ```

    such that the allowed resources for each storage are as follows:

    ```terraform
    allowed_object_storage         = ["MongoDB", "Redis"]
    allowed_table_storage          = ["MongoDB"]
    allowed_queue_storage          = ["MongoDB", "Amqp"]
    allowed_lease_provider_storage = ["MongoDB"]
    ```

3. execute this command to deploy ArmoniK:

    ```bash
    make all CONFIG_FILE=<Your configuration file> 
    ```

    such as `make all` executes three commands in the following order that you can execute separately:

   * `make init`
   * `make plan CONFIG_FILE=<Your configuration file>`
   * `make apply CONFIG_FILE=<Your configuration file>`

After the deployment you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_NAMESPACE
```
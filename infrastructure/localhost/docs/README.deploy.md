# Table of contents

1. [Software prerequisites](#software-prerequisites)
2. [Infrastructure source codes](#infrastructure-source-codes)
3. [Configuration file](#configuration-file)
4. [Deployment](#deployment)

# Software prerequisites <a name="software-prerequisites"></a>

The following resources should be installed upon you local machine :

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) version > 1.0.0
* [JQ](https://stedolan.github.io/jq/)

# Infrastructure source codes <a name="nfrastructure-source-codes"></a>

The source codes of resources to be deployed are defined in the directory [deploy/](../deploy). They contain two main
types of resources:

* **Storage services**: ArmoniK needs a single or different types of storage to store its different
  data ([storage](../deploy/storage)).
    * Object storage
    * Table
    * Queue
    * Lease provider
* **ArmoniK components**: are the components of the ArmoniK scheduler ([armonik](../deploy/armonik)).
    * Control plane
    * Compute plane composed of polling agent and compute

For the storage, three types of storage will be created as services in the Kubernetes cluster:

* MongoDB
* Redis
* ActiveMQ
* Shared volume used as NFS

# Configuration file <a name="configuration-file"></a>

Terraform needs a configuration file containing the list of parameters to configure the resources to be created. The
complete list of parameters and their types are defined in [List of parameters](../docs/template-of-parameters.tf). An
example of setting parameters of `object_storage`
resource is as follows:

```terraform
object_storage = {
  replicas = 1,
  port     = 6379,
  secret   = "object-storage-secret"
}
```

An example of a configuration file is given in [example-parameters.tfvars](../utils/example-parameters.tfvars). You can
make a copy to the file and change the values of each parameter of each resource if needed. This file will be used as
the input for `Terraform apply`.

# Deployment <a name="deployment"></a>

To deploy ArmoniK components and the storage services:

1. in the directory [deploy/](../deploy):

```bash
cd ./deploy
```

2. initialize a working directory containing Terraform configuration files:

```bash
make init 
```

3. execute the Terraform planning:

```bash
make plan CONFIG_FILE=<Your configuration file> 
```

4. deploy the resources:

```bash
make apply CONFIG_FILE=<Your configuration file> 
```

You can execute all these steps in one commandline:

```bash
make all CONFIG_FILE=<Your configuration file> 
```

After the deployment you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_NAMESPACE
```
# Table of contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Set environment variables](#set-environment-variables)
- [Deploy](#deploy)
    - [Kubernetes namespace](#kubernetes-namespace)
    - [Keda](#keda)
- [Clean-up](#clean-up)

# Introduction

Hereafter, You have instructions to deploy [KEDA](https://keda.sh/) on your Kubernetes cluster.

# Prerequisites

The following software are required :

* Kubernetes ([Install Kubernetes on dev/test local machine](docs/k3s.md))
* [Docker](https://docs.docker.com/engine/install/)
* [GNU make](https://www.gnu.org/software/make/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Helm](https://helm.sh/docs/intro/install/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

# Set environment variables

From the **root** of the repository, position yourself in directory `infrastructure/quick-deploy/keda`.

```bash
cd infrastructure/quick-deploy/keda
```

You need to set a list of environment variables [envvars.sh](envvars.sh) :

```bash
source envvars.sh
```

**or:**

```bash
export KEDA_KUBERNETES_NAMESPACE="default"
```

where:

- `KEDA_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for KEDA.

# Deploy

## Kubernetes namespace

You create a Kubernetes namespace for KEDA with the name set in the environment
variable`KEDA_KUBERNETES_NAMESPACE`:

```bash
make create-namespace
```

## Keda

The parameters of KEDA are defined in [sources/parameters.tfvars](sources/parameters.tfvars).

Execute the following command to install KEDA:

```bash
make deploy-keda
```

The Keda deployment generates an output file `sources/generated/keda-output.json`.

# Clean-up

To delete KEDA in Kubernetes, You can execute the following command:

```bash
make destroy-all
```

or execute the following commands:

```bash
make destroy-keda 
```

To clean-up and delete all generated files, You execute:

```bash
make clean-all
```

or:

```bash
make clean-keda 
``` 

### [Return to the infrastructure main page](../../README.md)

### [Return to the project main page](../../../README.md)




# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
    - [Software](#software)
    - [GCP credentials](#gcp-credentials)
- [Set environment variables](#set-environment-variables)
- [Prepare backend for Terraform](#preapre-backend-for-terraform)
- [Deploy infrastructure](#deploy-infrastructure)
    - [GCP VPC](#gcp-vpc)
    - [GCP GAR](#gcp-gar)
    - [GCP GKE](#gcp-gke)
    - [KEDA](#keda)
    - [Metrics server](#metrics-server)
    - [Storage](#storage)
    - [Monitoring](#monitoring)
- [Deploy ArmoniK](#deploy-armonik)
- [Merge multiple kubeconfig](#merge-multiple-kubeconfig)
- [Clean-up](#clean-up)

# Introduction

Hereafter, You have instructions to deploy infrastructure for ArmoniK on GCP cloud.

The infrastructure is composed of:

* GCP VPC
* GCP Artifact registry for docker images
* GKE
* [KEDA](https://keda.sh/)
* Storage:
    * GCS:
        * to save safely `.tfsate`
        * to upload `.dll` for worker pods
        * for input/output payloads
    * GCP Memorystore for Redis (in case where GCS is not used for payloads)
    * Onpremise MongoDB
* GCP service accounts for control-plane and compute-plane
* Monitoring:
    * Fluent-bit
    * Grafana
    * Metrics exporter
    * Prometheus
    * Seq server for structured log data of ArmoniK
* ArmoniK:
    * Control plane
    * Compute plane:
        * polling agent
        * workers
    * Ingress
    * Admin GUI

# Prerequisites

## Software

The following software or tool should be installed upon your local Linux machine or VM from which you deploy the
infrastructure:

* If You have Windows machine, You can install [WSL 2](../../docs/kubernetes/localhost/wsl2.md)
* [gcloud CLI](https://cloud.google.com/sdk/docs/install)
* [Docker](https://docs.docker.com/engine/install/)
* [GNU make](https://www.gnu.org/software/make/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) v1.23.6
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) version 1.0.9 and later

## GCP initialization

You must have credentials to be able to create GCP resources. You must
initialize [gcloud CLI](https://cloud.google.com/sdk/docs/install-sdk?hl=fr#initializing_the).

# Set environment variables

From the **root** of the repository, position yourself in directory `infrastructure/quick-deploy/gcp`.

```bash
cd infrastructure/quick-deploy/gcp
```

You need to set a list of environment variables [envvars.sh](envvars.sh) :

```bash
source envvars.sh
```

**or:**

```bash
export ARMONIK_REGION="europe-west1"
export ARMONIK_SUFFIX="main"
export ARMONIK_BUCKET_NAME="armonik-tfstate"
export ARMONIK_KUBERNETES_NAMESPACE="armonik"
export KEDA_KUBERNETES_NAMESPACE="default"
export PUBLIC_ACCESS_GKE=true
export TERRAFORM_PLUGINS=$HOME/.terraform.d/plugin-cache
```

where:

- `ARMONIK_REGION`: presents the region where all resources will be created
- `ARMONIK_SUFFIX`: will be used as suffix to the name of all resources
- `ARMONIK_BUCKET_NAME`: is the name of S3 bucket in which `.tfsate` will be safely stored
- `ARMONIK_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for ArmoniK
- `KEDA_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for [KEDA](https://keda.sh/)
- `PUBLIC_ACCESS_gke`: is boolean defining whether the GKE to be deployed should have a public access
- `TERRAFORM_PLUGINS`: directory path where save Terraform plugins

**Warning:** `ARMONIK_SUFFIX` must be *UNIQUE* to allow resources to have unique name in GCP

# Prepare backend for Terraform

Before deploying ArmoniK, you need to create a Google storage to save safely `.tfstate` files of Terraform.

# Deploy infrastructure

## GCP VPC

You need to create a Google Virtual Private Cloud (VPC) that provides an isolated virtual network environment. The
parameters of this VPC are in [vpc/parameters.tfvars](vpc/parameters.tfvars).

Execute the following command to create the VPC:

```bash
make deploy-vpc
```

The VPC deployment generates an output file `vpc/generated/vpc-output.json` which contains information needed for the
deployments of storage and Kubernetes.

## GCP Artifact Registry

You need to create a Google Artifact Registry (GAR) and push the container images needed for Kubernetes and
ArmoniK [gar/parameters.tfvars](gar/parameters.tfvars).

Execute the following command to create the GAR and push the list of container images:

```bash
make deploy-gar
```

The list of created GAR repositories are in `gar/generated/gar-output.json`.

## GCP GKE

You need to create a Google Kubernetes Engine cluster (GKE). The parameters of GKE to be created are defined
in [gke/parameters.tfvars](gke/parameters.tfvars).

Execute the following command to create the GKE:

```bash
make deploy-gke
```

**or:**

```bash
make deploy-gke VPC_PARAMETERS_FILE=<path-to-vpc-parameters>
```

where:

- `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/vpc-output.json` containing the information
  about the VPC previously created.

The GKE deployment generates an output file `gke/generated/gke-output.json`.

### Create Kubernetes namespace

After the GKE deployment, You create a Kubernetes namespaces for ArmoniK with the name set in the environment
variable`ARMONIK_KUBERNETES_NAMESPACE` and for KEDA with the name set in the environment
variable`KEDA_KUBERNETES_NAMESPACE`:

```bash
make create-namespace
```

## KEDA

The parameters of KEDA are defined in [keda/parameters.tfvars](keda/parameters.tfvars).

Execute the following command to install KEDA:

```bash
make deploy-keda
```

The Keda deployment generates an output file `keda/generated/keda-output.json`.

**NOTE:** Please note that KEDA must be deployed only ONCE on the same Kubernetes cluster.

## Storage

You need to create Google Cloud Storage for ArmoniK which are:

* Google Memorystore for Redis
* Google Cloud Storage to upload `.dll` for ArmoniK workers
* MongoDB as a Kubernetes service

The parameters of each storage are defined in [storage/parameters.tfvars](storage/parameters.tfvars).

Execute the following command to create the storage:

```bash
make deploy-storage
```

**or:**

```bash
make deploy-storage \
  VPC_PARAMETERS_FILE=<path-to-vpc-parameters> \
  GKE_PARAMETERS_FILE=<path-to-gke-parameters>
```

where:

- `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/vpc-output.json`
- `<path-to-gke-parameters>` is the **absolute** path to file `gke/generated/gke-output.json`

These files are input information for storage deployment containing the information about the VPC and GKE previously
created.

The storage deployment generates an output file `storage/generated/storage-output.json` which contains information
needed for ArmoniK.

## Monitoring

You deploy the following resources for monitoring ArmoniK :

* Seq to collect the ArmoniK application logs
* Grafana
* Prometheus

The parameters of each monitoring resources are defined in [monitoring/parameters.tfvars](monitoring/parameters.tfvars).

Execute the following command to create the monitoring tools:

```bash
make deploy-monitoring 
```

**or:**

```bash
make deploy-monitoring \
  GKE_PARAMETERS_FILE=<path-to-GKE-parameters> \
  STORAGE_PARAMETERS_FILE=<path-to-storage-parameters> 
```

where:

- `<path-to-gke-parameters>` is the **absolute** path to file `gke/generated/gke-output.json` containing the information
  about the VPC previously created.
- `<path-to-storage-parameters>` is the **absolute** path to file `storage/generated/storage-output.json` containing the
  information about the storage previously created.

The monitoring deployment generates an output file `monitoring/generated/monitoring-output.json` that contains
information needed for ArmoniK.

# Deploy ArmoniK

After deploying the infrastructure, You can install ArmoniK in GCP GKE. The installation deploys:

* ArmoniK control plane
* ArmoniK compute plane

Execute the following command to deploy ArmoniK:

```bash
make deploy-armonik 
```

**or:**

```bash
make deploy-armonik \
  STORAGE_PARAMETERS_FILE=<path-to-storage-parameters> \
  MONITORING_PARAMETERS_FILE=<path-to-monitoring-parameters>
```

where:

- `<path-to-storage-parameters>` is the **absolute** path to file `storage/generated/storage-output.json`
- `<path-to-monitoring-parameters>` is the **absolute** path to file `monitoring/generated/monitoring-output.json`

These files are input information for ArmoniK containing the information about storage and monitoring tools previously
created.

The ArmoniK deployment generates an output file `armonik/generated/armonik-output.json` that contains the endpoint URL
of ArmoniK control plane.

### All-in-one deploy

All commands described above can be executed with one command. To deploy infrastructure and ArmoniK in all-in-one
command, You execute:

```bash
make deploy-all
```

# Merge multiple kubeconfig

When accessing multiple Kubernetes clusters, you will have many kubeconfig files. By default, kubectl only looks for a
file named config in the `$HOME/.kube` directory.

So, to manage multiple Kubernetes clusters execute the following command:

```bash
make kubeconfig
```

Export `KUBECONFIG` as displayed by the above command.

# Clean-up

To delete all resources created in GCP, You can execute the following all-in-one command:

```bash
make destroy-all
```

**or:** execute the following commands in this order:

```bash
make destroy-armonik 
make destroy-monitoring 
make destroy-storage 
make destroy-keda
make destroy-gke 
make destroy-vpc 
make destroy-gar
```

To clean-up and delete all generated files, You execute:

```bash
make clean-all
```

**or:**

```bash
make clean-armonik 
make clean-monitoring 
make clean-storage 
make clean-keda
make clean-gke 
make clean-vpc 
make clean-gar
```




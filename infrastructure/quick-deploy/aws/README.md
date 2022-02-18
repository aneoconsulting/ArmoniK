# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
    - [Software](#software)
    - [AWS credentials](#aws-credentials)
- [Set environment variables](#set-environment-variables)
- [Prepare backend for Terraform](#preapre-backend-for-terraform)
- [Deploy infrastructure](#deploy-infrastructure)
    - [AWS ECR](#aws-ecr)
    - [AWS VPC](#aws-vpc)
    - [AWS EKS](#aws-eks)
    - [AWS storage](#aws-storage)
    - [Monitoring](#monitoring)
- [Deploy ArmoniK](#deploy-armonik)
- [Clean-up](#clean-up)

# Introduction

Hereafter, You have instructions to deploy infrastructure for ArmoniK on AWS cloud.

The infrastructure is composed of:

* AWS ECR for docker images
* AWS VPC
* Storage:
    * AWS S3 buckets:
        * to save safely `.tfsate`
        * to upload `.dll` for worker pods
    * AWS Elasticache (Redis engine)
    * Amazon MQ (ActiveMQ broker engine)
    * Onpremise MongoDB
* Monitoring:
    * Seq server for structured log data of ArmoniK
    * AWS CloudWatch
* ArmoniK:
    * Control plane
    * Compute plane:
        * polling agent
        * workers

# Prerequisites

## Software

The following software or tool should be installed upon your local Linux machine or VM from which you deploy the
infrastructure:

* If You have Windows machine, You can install [WSL 2](../../docs/kubernetes/localhost/wsl2.md)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) version 2
* [Docker](https://docs.docker.com/engine/install/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Helm](https://helm.sh/docs/intro/install/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## AWS credentials

You must have credentials to be able to create AWS resources. You must create and provide
your [AWS programmatic access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
in your environment as follows:

```bash
mkdir -p ~/.aws
cat <<EOF | tee ~/.aws/credentials
[default]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
EOF
```

You can check connectivity to AWS using the following command:

```bash
aws sts get-caller-identity
```

the output of this command should be as follows:

```bash
{
    "UserId": "<USER_ID>",
    "Account": "<ACCOUNT_ID>",
    "Arn": "arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>"
}
```

# Set environment variables

From the **root** of the repository, position yourself in directory `infrastructure/quick-deploy/aws`.

```bash
cd infrastructure/quick-deploy/aws
```

You need to set a list of environment variables [envvars.sh](envvars.sh) :

```bash
source envvars.sh
```

**or:**

```bash
export ARMONIK_PROFILE=default
export ARMONIK_REGION=eu-west-3
export ARMONIK_SUFFIX=main
export ARMONIK_BUCKET_NAME=armonik-tfstate
export ARMONIK_KUBERNETES_NAMESPACE=armonik
```

where:

- `ARMONIK_PROFILE`: defines your AWS profile which has credentials to deploy in AWS Cloud
- `ARMONIK_REGION`: presents the region where all resources will be created
- `ARMONIK_SUFFIX`: will be used as suffix to the name of all resources
- `ARMONIK_BUCKET_NAME`: is the name of S3 bucket in which `.tfsate` will be safely stored
- `ARMONIK_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for ArmoniK

# Prepare backend for Terraform

You need to create a S3 bucket to save safely `.tfstate` files of Terraform. This bucket will be encrypted with an AWS
KMS key.

Execute the following command to create the S3 bucket:

```bash
make deploy-s3-of-backend
```

# Deploy infrastructure

## AWS ECR

You need to create an AWS Elastic Container Registry (ECR) and push the container images needed for Kubernetes and
ArmoniK [ecr/parameters.tfvars](ecr/parameters.tfvars).

Execute the following command to create the ECR and push the list of container images:

```bash
make deploy-ecr
```

The list of created ECR repositories are in `ecr/generated/ecr-output.json`.

## AWS VPC

You need to create an AWS Virtual Private Cloud (VPC) that provides an isolated virtual network environment. The
parameters of this VPC are in [vpc/parameters.tfvars](vpc/parameters.tfvars).

Execute the following command to create the VPC:

```bash
make deploy-vpc
```

The VPC deployment generates an output file `vpc/generated/vpc-output.json` which contains information needed for the
deployments of storage and Kubernetes.

## AWS EKS

You need to create an AWS Elastic Kubernetes Service (EKS). The parameters of EKS to be created are defined
in [eks/parameters.tfvars](eks/parameters.tfvars).

Execute the following command to create the EKS:

```bash
make deploy-eks
```

**or:**

```bash
make deploy-eks VPC_PARAMETERS_FILE=<path-to-vpc-parameters>
```

where:

- `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/vpc-output.json` containing the information
  about the VPC previously created.

The EKS deployment generates an output file `eks/generated/eks-output.json`.

### Create Kubernetes namespace

After the EKS deployment, You create a Kubernetes namespace for ArmoniK with the name set in the environment
variable`ARMONIK_KUBERNETES_NAMESPACE`:

```bash
make create-namespace
```

## AWS storage

You need to create AWS storage for ArmoniK which are:

* AWS Elasticache with Redis engine
* Amazon MQ with ActiveMQ broker engine
* Amazon S3 bucket to upload `.dll` for ArmoniK workers
* MongoDB as a Kubernetes service

The parameters of each storage are defined in [storage/parameters.tfvars](storage/parameters.tfvars).

Execute the following command to create the storage:

```bash
make deploy-aws-storage
```

**or:**

```bash
make deploy-aws-storage \
  VPC_PARAMETERS_FILE=<path-to-vpc-parameters> \
  EKS_PARAMETERS_FILE=<path-to-eks-parameters>
```

where:

- `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/vpc-output.json`
- `<path-to-eks-parameters>` is the **absolute** path to file `eks/generated/eks-output.json`

These files are input information for storage deployment containing the information about the VPC and EKS previously
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
make deploy-monitoring EKS_PARAMETERS_FILE=<path-to-eks-parameters>
```

where:

- `<path-to-eks-parameters>` is the **absolute** path to file `eks/generated/eks-output.json` containing the information
  about the VPC previously created.

The monitoring deployment generates an output file `monitoring/generated/monitoring-output.json` that contains
information needed for ArmoniK.

# Deploy ArmoniK

After deploying the infrastructure, You can install ArmoniK in AWS EKS. The installation deploys:

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

# Clean-up

To delete all resources created in AWS, You can execute the following all-in-one command:

```bash
make destroy-all
```

or execute the following commands in this order:

```bash
make destroy-armonik 
make destroy-monitoring 
make destroy-aws-storage 
make destroy-eks 
make destroy-vpc 
make destroy-ecr
```

To clean-up and delete all generated files, You execute:

```bash
make clean-all
```

or:

```bash
make clean-armonik 
make clean-monitoring 
make clean-aws-storage 
make clean-eks 
make clean-vpc 
make clean-ecr
```

### [Return to the infrastructure main page](../../README.md)

### [Return to the project main page](../../../README.md)




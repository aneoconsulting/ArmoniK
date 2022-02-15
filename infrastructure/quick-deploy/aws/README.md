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
    - [AWS storage](#aws-storage)
    - [AWS EKS](#aws-eks)

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

* If You have Windows machine, You can install [WSL 2](../../kubernetes/onpremise/localhost/wsl2.md)
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

You need to set a list of environment variables :

```bash
export ARMONIK_PROFILE=default
export ARMONIK_REGION=eu-west-3
export ARMONIK_TAG=main
export ARMONIK_BUCKET_NAME=armonik-tfstate
export ARMONIK_KUBERNETES_NAMESPACE=armonik
```

where:

- `ARMONIK_PROFILE`: defines your AWS profile which has credentials to deploy in AWS Cloud
- `ARMONIK_REGION`: presents the region where all resources will be created
- `ARMONIK_TAG`: will be used as suffix to the name of all resources
- `ARMONIK_BUCKET_NAME`: is the name of S3 bucket in which `.tfsate` will be safely stored
- `ARMONIK_KUBERNETES_NAMESPACE`: is the namespace in Kubernetes for ArmoniK

You can source these environment variables form the file [envvars.sh](./envvars.sh). You can modify the values of each
variable. From the **root** of the repository, position yourself in directory `infrastructure/quick-deploy/aws`
and:

```bash
source envvars.sh
```

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

## AWS VPC

You need to create an AWS Virtual Private Cloud (VPC) that provides an isolated virtual network environment. The
parameters of this VPC are in [vpc/parameters.tfvars](vpc/parameters.tfvars).

Execute the following command to create the VPC:

```bash
make deploy-vpc
```

The VPC deployment generate an output file `vpc/generated/output.json` that contains information needed for the
deployments of storage and Kubernetes.

## AWS storage

You need to create AWS storage for ArmoniK which are:

* AWS Elasticache with Redis engine
* Amazon MQ with ActiveMQ broker engine
* S3 bucket to upload `.dll` for ArmoniK workers

The parameters of each storage are defined in [storage/parameters.tfvars](storage/parameters.tfvars).

Execute the following command to create the storage:

```bash
make deploy-aws-storage VPC_PARAMETERS_FILE=<path-to-vpc-parameters>
```

where `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/output.json`
containing the information about the VPC previously created.

The storage deployment generate an output file `storage/generated/output.json` that contains information needed for
ArmoniK.

## AWS EKS

You need to create an AWS Elastic Kubernetes Service (EKS). The parameters of EKS to be created are defined
in [eks/parameters.tfvars](eks/parameters.tfvars).

Execute the following command to create the EKS:

```bash
make deploy-eks VPC_PARAMETERS_FILE=<path-to-vpc-parameters> STORAGE_PARAMETERS_FILE=<path-to-storage-parameters>
```

where `<path-to-vpc-parameters>` is the **absolute** path to file `vpc/generated/output.json`
and `<path-to-storage-parameters>` is the **absolute** path to file `storage/generated/output.json` containing the
information about the VPC and storage previously created.

The EKS deployment generate an output file `eks/generated/output.json`.

### [Return to the Main page](../../README.md)




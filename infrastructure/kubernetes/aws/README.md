# Table of contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
    1. [Software](#software)
    2. [AWS credentials](#aws-credentials)
3. [Create an Amazon ECR](#create-an-amazon-ecr)
4. [Create an Amazon EKS](#create-an-amazon-eks)

# Introduction

Hereafter you have a list of prerequisites and resources to create an Elastic Kubernetes Service (EKS) in AWS cloud.

# Prerequisites

## Software

The following software should be installed upon you local machine:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) version 2
* [Docker](https://docs.docker.com/engine/install/)
* [JQ](https://stedolan.github.io/jq/download/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/)
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

# Create an Amazon ECR

Some resources needed to deploy ArmoniK scheduler, as storage and Kubernetes, use container images from the public
DockerHub repository, ANEO DockerHub repository and AWS public repositories. We recommend creating a private **Amazon
Elastic Container Registry (ECR)** to which you will upload those container images and from which EKS pull its container
images. This also allows avoiding anonymous throttling limitations on public repositories.

Follow the instructions presented in [Create Amazon ECR](ecr/README.md).

# Create an Amazon EKS

**Amazon Elastic Kubernetes Service (EKS)** is a managed service that you can use to run Kubernetes on AWS cloud without
needing to install, operate, and maintain your own Kubernetes control plane or worker nodes.

Follow the instructions presented in [Create Amazon ECR](ekr/README.md).

### [Return to ArmoniK deployments](../../README.md#armonik-deployments)



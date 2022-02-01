# Table of contents

1. [Introduction](#introduction)
2. [Prepare input parameters](#prepare-input-parameters)
3. [Deploy](#deploy)
4. [Clean-up](#clean-up)

# Introduction

Hereafter you have instructions to create a private Amazon Elastic Container Registry (ECR).

# Prepare input parameters

Before creating an Amazon ECR, you must prepare the [parameters.tfvars](parameters.tfvars) containing:

* Global parameters as AWS region:

```terraform
# AWS profile
profile = "default"

# Region
region = "eu-west-3"

# TAG (suffix)
tag = ""
```

* ARN of the KMS key to encrypt/decrypt ECR repositories:

```terraform
# KMS to encrypt ECR repositories
kms_key_id = ""
```

* List of container images to upload on the private ECR, example:

```terraform
# List of ECR repositories to create
repositories = [
  {
    name  = "armonik-control-plane"
    image = "dockerhubaneo/armonik_control"
    tag   = "0.4.0"
  },
  {
    name  = "armonik-polling-agent"
    image = "dockerhubaneo/armonik_pollingagent"
    tag   = "0.4.0"
  },
  {
    name  = "armonik-worker"
    image = "dockerhubaneo/armonik_worker_dll"
    tag   = "0.1.2-SNAPSHOT.4.cfda5d1"
  },
  {
    name  = "cluster-autoscaler"
    image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
    tag   = "v1.21.0"
  },
  {
    name  = "aws-node-termination-handler"
    image = "amazon/aws-node-termination-handler"
    tag   = "v1.10.0"
  }
]
```

> **_NOTE:_** You have th list of parameters and their type/default values in [parameters.md](parameters.md)

# Deploy

From the **root** of the repository, position yourself in directory `infrastructure/kubernetes/aws/ecr` and execute:

```bash
make all PARAMETERS_FILE=parameters.tfvars 
```

or:

```bash
make all
```

After the deployment, an output file `generated/output.json` is generated containing the list of created ECR
repositories.

# Clean-up

**If you want** to delete all ECR repositories, execute the command:

```bash
make destroy PARAMETERS_FILE=parameters.tfvars 
```

or:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```

### [Create Amazon EKS](../eks/README.md)

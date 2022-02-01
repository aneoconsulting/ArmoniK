# Table of contents

1. [Introduction](#introduction)
2. [Prepare input parameters](#prepare-input-parameters)
3. [Deploy](#deploy)
4. [Clean-up](#clean-up)

# Introduction

Hereafter you have instructions to create a private Amazon Elastic Kubernetes Service (EKS).

# Prepare input parameters

Before creating an Amazon EKS, you must prepare the parameters [*.tfvars](parameters) containing:

* Global parameters [global-parameters.tfvars](parameters/global-parameters.tfvars) as AWS region.
* VPC parameters [vpc-parameters.tfvars](parameters/vpc-parameters.tfvars).
* EKS parameters [eks-parameters.tvvars](parameters/eks-parameters.tfvars).

> **_NOTE:_** You have th list of parameters and their type/default values in [parameters.md](parameters.md)

# Deploy

You will deploy :
* Amazon VPC
* Amazon S3 (as shared storage for ArmoniK workers)
* Amazon KMS key for encrypt/decrypt : logs of the VPC and EKS, EBS of nodes, S3
* Amazon EKS

From the **root** of the repository, position yourself in directory `infrastructure/kubernetes/aws/eks` and execute:

```bash
make all PARAMETERS_DIR=<parameters_dir>
```

or:

```bash
make all
```

After the deployment, an output file `generated/output.json` is generated containing the list of created EKS
repositories.

# Clean-up

**If you want** to delete all the deployments, execute the command:

```bash
make destroy PARAMETERS_DIR=<parameters_dir>
```

or:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```

### [Return to ArmoniK deployments](../../../README.md#armonik-deployments)

# Table of contents

1. [Introduction](#introduction)
2. [Software prerequisites](#software-prerequisites)
3. [Prepare your Kubernetes cluster](./docs/README.kubernetes.md)
4. [Deploy ArmoniK](./docs/README.deploy.md)
5. [Clean-up](./docs/README.clean.md)

# Introduction <a name="introduction"></a>

Hereafter, we describe the steps to deploy ArmoniK on **onpremise cluster**. All components of ArmoniK and services used
with ArmoniK (example: different storage) are deployed as services in the Kubernetes cluster.

# Software prerequisites <a name="software-prerequisites"></a>

The following resources should be installed upon you local machine :

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) version > 1.19
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) version > 1.0.0
* [JQ](https://stedolan.github.io/jq/)

# Prepare your Kubernetes cluster <a name="prepare-your-kubernetes-cluster"></a>

Before deploying ArmoniK scheduler, you must first install and prepare the Kubernetes cluster on your local machine.

Follow the instructions described in [Kubernetes docs](./docs/README.kubernetes.md) to install and configure your
Kubernetes cluster.

# Deploy ArmoniK cluster <a name="deploy-armonik"></a>

A set of instructions are presented in [ArmoniK local deployment](./docs/README.deploy.md) to deploy ArmoniK's
components and all needed services onpremise cluster.

# Clean-up <a name="clean-up"></a>

To delete ArmoniK and uninstall the Kubernetes cluster on you local machine,
follow [Clean-up docs](./docs/README.clean.md).
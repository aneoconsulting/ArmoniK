# Table of contents

1. [Introduction](#introduction)
2. [Prepare your Kubernetes cluster](#prepare-your-kubernetes-cluster)
3. [Deploy ArmoniK](#deploy-armonik)
4. [Clean-up](#clean-up)

# Introduction <a name="introduction"></a>

Hereafter, we describe the steps to deploy ArmoniK on **local machine**. All components of ArmoniK and services used
with ArmoniK (example: different storage) are deployed as services in the Kubernetes cluster.

# Prepare your Kubernetes cluster <a name="prepare-your-kubernetes-cluster"></a>

Before deploying ArmoniK scheduler, you must first install and prepare the Kubernetes cluster on your local machine.

Follow the instructions described in [Kubernetes docs](./docs/README.kubernetes.md) to install and configure your
Kubernetes cluster.

# Deploy ArmoniK cluster <a name="deploy-armonik"></a>

A set of instructions are presented in [ArmoniK local deployment](./docs/README.deploy.md) to deploy ArmoniK's
components and all needed services on your local machine.

# Clean-up <a name="clean-up"></a>

To delete ArmoniK and uninstall the Kubernetes cluster on you local machine,
follow [Clean-up docs](./docs/README.clean.md).
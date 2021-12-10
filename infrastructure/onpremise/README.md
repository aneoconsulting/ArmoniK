# Table of contents

1. [Introduction](#introduction)
2. [Prepare your Kubernetes cluster](old/docs/README.kubernetes.md)
3. [Deploy ArmoniK](old/docs/README.deploy.md)
4. [Clean-up](old/docs/README.clean.md)

# Introduction <a name="introduction"></a>

Hereafter, we describe the steps to deploy ArmoniK **on-premise**. All components of ArmoniK are deployed on a remote
Kubernetes cluster.

# Prepare your Kubernetes cluster <a name="prepare-your-kubernetes-cluster"></a>

Before deploying ArmoniK scheduler, you must first install and prepare the Kubernetes cluster.

> **_NOTE:_** A developer or tester can deploy a small cluster in AWS using these [source codes](./utils/cluster/README.md). This is useful for the development and testing only!

Follow the instructions described in [Kubernetes docs](./docs/README.kubernetes.md) to install and configure your
Kubernetes cluster.

# Deploy ArmoniK <a name="deploy-armonik"></a>

A set of instructions are presented in [ArmoniK onpremise deployment](./docs/README.deploy.md) to deploy ArmoniK's
components on Kubernetes cluster.

# Clean-up <a name="clean-up"></a>

To delete ArmoniK follow [Clean-up docs](./docs/README.clean.md).
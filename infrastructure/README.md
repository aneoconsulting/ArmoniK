# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Software prerequisites](#software-prerequisites)
- [ArmoniK deployments](#armonik-deployments)
  - [Install infrastructure requirements](#install-infrastructure-requirements)
    - [Install Kubernetes](#install-kubernetes)
    - [Install storage](#install-storage)
  - [Install ArmoniK](#install-armonik)
- [Quick install](#quick-install)
  - [On dev/test local machine](#on-devtest-local-machine)
- [All in One command to deploy](#all-in-one-command-to-deploy)
  - [On dev/test local machine](#on-devtest-local-machine-1)

# Introduction

In this project, we present the different steps to deploy ArmoniK scheduler in different environments.

# Software prerequisites

[Software prerequisites](utils/prerequisites.md).

# ArmoniK deployments

Your can deploy ArmoniK scheduler:

1. on your local machine or a VM, Linux machine or Windows machine on WSL 2, on a single-node of Kubernetes. This is
   useful for development and testing environment only!
2. on an onpremise cluster composed of a master node and several worker nodes of Kubernetes.
3. on Cloud as AWS, Azure or GCP.

## Install infrastructure requirements

Before installing ArmoniK scheduler, you must install **Kubernetes** and the different **storage requirements**.

### Install Kubernetes

ArmoniK must be deployed on a Kubernetes. You can follow the instructions given
in [Kubernetes installation](kubernetes/README.md).

### Install storage

ArmoniK needs a single or different storage to store its different types of data (object, table and queue). You can
follow [Storage installation](storage/README.md) to create the needed storage.

## Install ArmoniK

After the installation of Kubernetes and the needed storage, you can install ArmoniK by following the instructions given
in [ArmoniK installation](armonik/README.md).

# Quick install

## On dev/test local machine

You can follow instructions described in [Quick deploy ArmoniK on local machine](quick-deploy/localhost/README.md) to
install ArmoniK and its infrastructure requirements upon your local machine.

# All in One command to deploy

## On dev/test local machine

If you do not modify any default configuration you can directly take a script all-in-one to deploy Storage and Armonik in the same command. Please go the page : [All-In-One script page](quick-deploy/localhost/All-In-One.md)
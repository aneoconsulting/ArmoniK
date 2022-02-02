# Table of contents

1. [Introduction](#introduction)
2. [Software prerequisites](#software-prerequisites)
3. [ArmoniK deployments](#armonik-deployments)
    1. [Install infrastructure requirements](#install-infrastructure-requirements)
        1. [Install Kubernetes](#install-kubernetes)
        2. [Install storage](#install-storage)
    2. [Install ArmoniK](#install-armonik)
4. [Quick install](#quick-install)

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







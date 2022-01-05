# Table of contents

1. [Introduction](#introduction)
2. [Infrastructure requirements](#infrastructure-requirements)
    1. [Kubernetes](#kubernetes)
    2. [Storage](#storage)

# Introduction

Your can deploy ArmoniK scheduler:

1. on your local machine or a VM, Linux machine or Windows machine on [WSL 2](../wsl2.md), on a single-node of
   Kubernetes. This is useful for development and testing environment only!
2. on an onpremise cluster composed of a master node and several worker nodes of Kubernetes.

> **_NOTE:_** A developer or tester can deploy a small cluster in AWS using these [Terraform source codes](../../utils/create-cluster). This is useful for the development and testing only!

# Infrastructure requirements

Before installing ArmoniK scheduler, you must install Kubernetes and the different storage requirements.

## Kubernetes

If you do not have Kubernetes already installed, you can follow these instructions:

* for a development and testing environment on [a local machine or a VM](../kubernetes/kubernetes-on-single-node.md).
* for an [onpremise cluster](../kubernetes/kubernetes-on-cluster.md)

## Storage

ArmoniK needs a single or different storage to store its different types of data :

* Object
* Table
* Queue
* Lease provider
* External cache

The endpoint urls and access rights/connection strings to these storage resources must be passed to ArmoniK via a
configuration file.

If these storage resources are not already created, you can follow [Storage creation for ArmoniK](../../storage/README.md)
to create the needed storage.
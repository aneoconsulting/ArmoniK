# Table of contents

1. [Introduction](#introduction)
2. [Software prerequisites](#software-prerequisites)
    1. [Dependencies](#dependencies)
    2. [Docker](#docker)
    3. [Kubectl](#kubectl)
    4. [Terraform](#terraform)
3. [ArmoniK deployments](#armonik-deployments)
    1. [Onpremise](#onpremise)
        1. [Infrastructure requirements](#infrastructure-requirements)

# Introduction <a name="introduction"></a>

ArmoniK is a high throughput compute grid project using Kubernetes. The project provides a reference architecture that
can be used to build and adapt a modern high throughput compute solution on-premise or using Cloud services, allowing
users to submit high volumes of short and long-running tasks and scaling environments dynamically.

In this project, we present the different steps to deploy ArmoniK scheduler in different environments.

# Software prerequisites <a name="software-prerequisites"></a>

The following software should be installed upon your machine regardless of the environment of the deployment. This
machine can host Kubernetes for dev/test environment, or the login machine to deploy and manage ArmoniK on a distant
Kubernetes cluster.

***Warning:*** If you have a **Windows machine** you must first install [WSL 2 and SystemD](./docs/wsl2.md)
before installing the software prerequisites.

## Dependencies <a name="dependencies"></a>

First you must install the following packages:

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release jq
```

## Docker <a name="docker"></a>

The procedure to install [Docker](https://docs.docker.com/engine/install/ubuntu/):

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Kubectl <a name="kubectl"></a>

The Kubernetes CLI (kubectl), allows you to run commands against Kubernetes clusters. You must use
a [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) version that is within one minor version
difference of your cluster. For example, a v1.23 client can communicate with v1.22, v1.23, and v1.24 control planes.
Using the latest compatible version of kubectl helps avoid unforeseen issues.

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

## Terraform <a name="terraform"></a>

The procedure to install [Terraform](https://www.terraform.io/docs/cli/install/apt.html):

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform
```

# ArmoniK deployments <a name="armonik-deployments"></a>

This section presents the list of infrastructure requirements and their configurations (Kubernetes and storage) and
ArmoniK deployments in different environments (onpremise and cloud).

## Onpremise <a name="onpremise"></a>

Your can deploy ArmoniK scheduler:

1. on your local machine or a VM, Linux machine or Windows machine on [WSL 2](./docs/wsl2.md), on a single-node of
   Kubernetes. This is useful for development and testing environment only!
2. on an onpremise cluster composed of a master node and several worker nodes of Kubernetes.

> **_NOTE:_** A developer or tester can deploy a small cluster in AWS using these [Terraform source codes](./utils/cluster-on-aws). This is useful for the development and testing only!

### Infrastructure requirements <a name="infrastructure-requirements"></a>

Before installing ArmoniK scheduler, you must install Kubernetes and the different storage requirements.

#### Kubernetes

If you do not have Kubernetes already installed, you can follow these instructions:

* for a development and testing environment on [a local machine or a VM](docs/kubernetes/kubernetes-on-single-node.md).
* for an [onpremise cluster](docs/kubernetes/kubernetes-on-cluster.md)

#### Storage

ArmoniK needs a single or different storage to store its different types of data :

* Object
* Table
* Queue
* Lease provider
* External cache

The endpoint urls and access rights/connection strings to these storage resources must be passed to ArmoniK via a
configuration file.

To date, the storage resources allowed for each type of ArmoniK data are as follows:

```json
{
  "allowed_object_storage": [
    "MongoDB",
    "Redis"
  ],
  "allowed_table_storage": [
    "MongoDB"
  ],
  "allowed_queue_storage": [
    "MongoDB",
    "Amqp"
  ],
  "allowed_lease_provider_storage": [
    "MongoDB"
  ],
  "allowed_external_storage": [
    "Redis"
  ]
}
```

If these storage resources are not already created, you can follow [Storage creation for ArmoniK]() to create the needed
storage.




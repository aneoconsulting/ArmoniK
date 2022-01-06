# Table of contents

1. [Introduction](#introduction)
2. [Infrastructure requirements](#infrastructure-requirements)
    1. [Kubernetes](#kubernetes)
    2. [Storage](#storage)
3. [Onpremise deployment of ArmoniK](#deploy-armonik)
    1. [Set environment variables](#set-environment-variables)
    2. [Create a namespace for ArmoniK](#create-a-namespace-for-armonik)
    3. [Create Kubernetes secrets](#create-kubernetes-secrets)
        1. [Redis secret](#redis-secret)
        2. [ActiveMQ secret](#activemq-secret)
    4. [Deploy](#deploy)

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

> **_NOTE:_** External cache is optional, and it is necessary only for HTC Mock sample !

The endpoint urls and access rights/connection strings to these storage resources must be passed to ArmoniK via a
configuration file.

If these storage resources are not already created, you can
follow [Storage creation for ArmoniK](../../storage/README.md)
to create the needed storage.

# Deploy ArmoniK

## Set environment variables

The project needs to define and set environment variables for deploying the infrastructure. The main environment
variables are:

```buildoutcfg
# Armonik namespace in the Kubernetes
export ARMONIK_NAMESPACE=<Your namespace in kubernetes>

# Directory path of the Redis certificates
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the Redis certificates>
    
# Name of Redis secret
export ARMONIK_REDIS_SECRET_NAME=<You kubernetes secret for the Redis storage>

# Directory path of the ActiveMQ credentials
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=<Your directory path of the ActiveMQ credentials>
    
# Name of ActiveMQ secret
export ARMONIK_ACTIVEMQ_SECRET_NAME=<You kubernetes secret for the ActiveMQ storage>
```

**Mandatory:** To set these environment variables, for example:

1. position yourself in the current directory `infrastructure/armonik/` from the **root** of the repository.

2. copy the [template file](../../utils/envvars.conf):

   ```bash
   cp ../utils/envvars.conf ./envvars.conf
   ```

3. modify the values of variables if needed in `./envvars.conf`.

4. Source the file of configuration:

   ```bash
   source ./envvars.conf
   ```

# Create a namespace for ArmoniK

**Mandatory:** Before deploring the ArmoniK resources, you must first create a namespace in the Kubernetes cluster for
ArmoniK:

```bash
kubectl create namespace $ARMONIK_NAMESPACE
```

You can see all active namespaces in your Kubernetes as follows:

```bash
kubectl get namespaces
```

# Create Kubernetes secrets

You create the secret for each storage only if you want to use these storages. In the following, we give examples to
create secrets for some storage.

## Redis secret

Redis uses SSL/TLS support using certificates. In order to support TLS, Redis is configured with a X.509
certificate (`cert.crt`) and a private key (`cert.key`). In addition, it is necessary to specify a CA certificate bundle
file (`ca.crt`) or path to be used as a trusted root when validating certificates. A SSL certificate of type `PFX` is
also used (`certificate.pfx`).

Execute the following command to create the Redis client secret in Kubernetes based on the certificates created and
saved in the directory `$ARMONIK_REDIS_CERTIFICATES_DIRECTORY`. In this project, we have certificates for test
in [credentials](../../credentials) directory. Create a Kubernetes secret for Redis client:

```bash
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
```

## ActiveMQ storage

ActiveMQ client use a file `amqp-credentials.json`. This is the file which stores user credentials.

Execute the following command to create the ActiveMQ client secret in Kubernetes based on the `amqp-credentials.json`
created and saved in the directory `$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY`. In this project, we have a file of
name `amqp-credentials.json` in [credentials](../../credentials) directory. Create a Kubernetes secret for the ActiveMQ
client:

```bash
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json
```

# Deploy

The instructions are described in [ArmoniK deployment](../../armonik/README.md).
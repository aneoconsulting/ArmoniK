# Table of contents

1. [Introduction](#introduction)
2. [Allowed storage resources](#allowed-storage-resources)
3. [Set environment variables](#set-environment-variables)
4. [Create a namespace for ArmoniK storage](#create-a-namespace-for-armonik-storage)
5. [Create Kubernetes secrets](#create-kubernetes-secrets)
    1. [Redis server secret](#redis-server-secret)
    2. [ActiveMQ server secret](#activemq-server-secret)
    3. [MongoDB server secret](#mongodb-server-secret)
6. [Create storage](#create-storage)
    1. [Prepare input parameters](#prepare-input-parameters)
    2. [Deploy](#deploy)
    3. [Clean-up](#clean-up)

# Introduction

Hereafter you have instructions to create onpremise storage resources, as Kubernetes services, needed for ArmoniK.

# Allowed storage resources

To date, the storage resources allowed for each type of ArmoniK data are defined
in [allowed storage resources](../../modules/needed-storage/storage_for_each_armonik_data.tf).

# Set environment variables

You must set environment variables for deploying the storage resources. The
main [environment variables](../../utils/envvars-storage.conf) are:

```buildoutcfg
# Armonik storage namespace in the Kubernetes
export ARMONIK_STORAGE_NAMESPACE=<Your namespace in kubernetes>

# Directory path of the Redis certificates
export ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the Redis certificates>
    
# Name of Redis secret
export ARMONIK_STORAGE_REDIS_SECRET_NAME=<You kubernetes secret for the Redis>

# Directory path of the ActiveMQ credentials
export ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY=<Your directory path of the ActiveMQ credentials>
export ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY=<Your directory path of the ActiveMQ certificates>
    
# Name of ActiveMQ secret
export ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME=<You kubernetes secret for the ActiveMQ>

# Directory path of the MongoDB credentials
export ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY=<Your directory path of the MongoDB certificates>

# Name of MongoDB secret
export ARMONIK_STORAGE_MONGODB_SECRET_NAME=<You kubernetes secret for the MongoDB>
```

**Mandatory:** You must set these environment variables:

From the **root** of the repository, position yourself in directory `infrastructure/storage/onpremise` and
source [envvars-storage.conf](../../utils/envvars-storage.conf):

```bash
   source infrastructure/utils/envvars-storage.conf
```

# Create a namespace for ArmoniK storage

**Mandatory:** Before deploring the ArmoniK storage resources, you must first create a namespace in the Kubernetes:

```bash
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE
```

You can see all active namespaces in your Kubernetes as follows:

```bash
kubectl get namespaces
```

# Create Kubernetes secrets

You create the secret for each storage only if you want to create the needed storage. In the following, we give examples
to create secrets for some storage.

## Redis server secret

Example of certificates for Redis server are in [Redis certificates](../../security/certificates). Execute the following
command to create the Redis server secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key
```

## ActiveMQ server secret

Example of certificates are in [ActiveMQ certificates](../../security/certificates) and credentials for authentication
are in [ActiveMQ credentials](../../security/credentials). Execute the following command to create the ActiveMQ server
secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=certificate.pfx=$ARMONIK_STORAGE_ACTIVEMQ_CERTIFICATES_DIRECTORY/certificate.pfx \
        --from-file=jetty-realm.properties=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties
```

## MongoDB server secret

Example of certificates for MongoDB server are in [MongoDB certificates](../../security/certificates). Execute the
following command to create the MongoDB server secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_STORAGE_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=mongodb.pem=$ARMONIK_STORAGE_MONGODB_CERTIFICATES_DIRECTORY/cert.pem
```

# Create storage

## Prepare input parameters

Before deploying the storages, you must prepare the [parameters.tfvars](parameters.tfvars) containing a list of
parameters for storages to be created.

> **_NOTE:_** You have th list of parameters and their type/default values in [parameters.md](parameters.md)

## Deploy

From the **root** of the repository, position yourself in directory `infrastructure/storage/onpremise` and execute:

```bash
make all PARAMETERS_FILE=parameters.tfvars 
```

or:

```bash
make all
```

After the deployment, an output file `generated/output.json` is generated containing the list of created storage.

## Clean-up

**If you want** to delete all storage, execute the command:

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

### [Return to ArmoniK deployments](../../README.md#armonik-deployments)

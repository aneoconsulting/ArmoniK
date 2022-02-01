# Table of contents

1. [Introduction](#introduction)
2. [Set environment variables](#set-environment-variables)
3. [Create a namespace for ArmoniK storage](#create-a-namespace-for-armonik-storage)
4. [Create Kubernetes secrets](#create-kubernetes-secrets)
    1. [Redis client secret](#redis-client-secret)
    2. [ActiveMQ client secret](#activemq-client-secret)
    3. [MongoDB client secret](#mongodb-client-secret)
5. [Prepare input parameters](#prepare-input-parameters)
6. [Deploy](#deploy)
7. [Clean-up](#clean-up)

# Introduction

Hereafter you have instructions to deploy ArmoniK in Kubernetes.

# Set environment variables

You must set environment variables for deploying ArmoniK. The
main [environment variables](../../utils/envvars-armonik.conf) are:

```buildoutcfg
# Armonik namespace in the Kubernetes
export ARMONIK_NAMESPACE=<Your namespace in kubernetes>

# Armonik monitoring namespace in the Kubernetes
export ARMONIK_MONITORING_NAMESPACE=<Your namespace in kubernetes for monitoring ArmoniK>

# Directory path of the Redis certificates
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the Redis certificates>
export ARMONIK_REDIS_CREDENTIALS_DIRECTORY=<Your directory path of the Redis credentials>
    
# Name of Redis secret
export ARMONIK_REDIS_SECRET_NAME=<You kubernetes secret for the Redis storage>

# Directory path of the certificates of external Redis
export ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the certificates of external Redis>
export ARMONIK_EXTERNAL_REDIS_CREDENTIALS_DIRECTORY=<Your directory path of the credentials of external Redis>
    
# Name of secret of external Redis
export ARMONIK_EXTERNAL_REDIS_SECRET_NAME=<You kubernetes secret for the external Redis storage>

# Directory path of the ActiveMQ credentials
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=<Your directory path of the ActiveMQ credentials>
export ARMONIK_ACTIVEMQ_CERTIFICATES_DIRECTORY=<Your directory path of the ActiveMQ certificates>
    
# Name of ActiveMQ secret
export ARMONIK_ACTIVEMQ_SECRET_NAME=<You kubernetes secret for the ActiveMQ storage>

# Directory path of the MongoDB credentials
export ARMONIK_MONGODB_CREDENTIALS_DIRECTORY=<Your directory path of the MongoDB credentials>
export ARMONIK_MONGODB_CERTIFICATES_DIRECTORY=<Your directory path of the MongoDB certificates>

# Name of MongoDB secret
export ARMONIK_MONGODB_SECRET_NAME=<You kubernetes secret for the MongoDB storage>
```

**Mandatory:** You must set these environment variables:

From the **root** of the repository, source [envvars-armonik.conf](../../utils/envvars-armonik.conf):

```bash
   source infrastructure/utils/envvars-armonik.conf
```

# Create a namespace for ArmoniK

**Mandatory:** Before deploring the ArmoniK resources, you must first create a namespace in the Kubernetes cluster for
ArmoniK:

```bash
kubectl create namespace $ARMONIK_NAMESPACE
kubectl create namespace $ARMONIK_MONITORING_NAMESPACE
```

You can see all active namespaces in your Kubernetes as follows:

```bash
kubectl get namespaces
```

# Create Kubernetes secrets

You create the secret for each storage only if you want to use these storages. In the following, we give examples to
create secrets for some storage.

## Redis client secret

Example of certificates for Redis client are in [Redis certificates](../../security/certificates) and credentials of
authentication are in [Redis credentials](../../security/credentials). Execute the following command to create the Redis
server secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=redis_credentials=$ARMONIK_REDIS_CREDENTIALS_DIRECTORY/redis-credentials.json
        
kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=redis_credentials=$ARMONIK_REDIS_CREDENTIALS_DIRECTORY/redis-credentials.json
```

## ActiveMQ Client secret

Example of certificates for ActiveMQ client are in [ActiveMQ certificates](../../security/certificates) and credentials
of authentication are in [ActiveMQ credentials](../../security/credentials). Execute the following command to create the
ActiveMQ server secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_ACTIVEMQ_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json
```

## MongoDB client secret

Example of certificates for MongoDB client are in [MongoDB certificates](../../security/certificates) and credentials of
authentication are in [MongoDB credentials](../../security/credentials). Execute the following command to create the
MongoDB server secret in Kubernetes:

```bash
kubectl create secret generic $ARMONIK_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_file=$ARMONIK_MONGODB_CERTIFICATES_DIRECTORY/chain.p7b \
        --from-file=mongodb_credentials=$ARMONIK_MONGODB_CREDENTIALS_DIRECTORY/mongodb-credentials.json
```

# Prepare input parameters

Before deploying ArmoniK, you must prepare the parameters [*.tfvars](parameters) containing:

* Storage parameters [storage-parameters.tfvars](parameters/storage-parameters.tfvars).
* Monitoring parameters [monitoring-parameters.tfvars](parameters/monitoring-parameters.tfvars).
* ArmoniK parameters [armonik-parameters.tvvars](parameters/armonik-parameters.tfvars).

> **_NOTE:_** You have th list of parameters and their type/default values in [parameters.md](parameters.md)

# Deploy

You will deploy :

* ArmoniK
* Monitoring tools as Seq to manage ArmoniK logs

From the **root** of the repository, position yourself in directory `infrastructure/armonik` and execute:

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
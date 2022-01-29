# Table of contents

1. [Introduction](#introduction)
2. [Allowed storage resources](#allowed-storage-resources)
3. [Set environment variables](#set-environment-variables)
4. [Create a namespace for ArmoniK storage](#create-a-namespace-for-armonik-storage)
5. [Create Kubernetes secrets](#create-kubernetes-secrets)
    1. [Redis server secret](#redis-server-secret)
    2. [ActiveMQ server secret](#activemq-server-secret)
    3. [MongoDB server secret](#mongodb-server-secret)
6. [Create storages on Kubernetes](#create-storages-on-kubernetes)
    1. [Prepare the configuration file](#prepare-the-configuration-file)
    2. [Deploy](#deploy)
    3. [Clean-up](#clean-up)

# Introduction

Hereafter we present the creation of onpremise storage resources needed for ArmoniK on Kubernetes cluster.

# Allowed storage resources

To date, the storage resources allowed for each type of ArmoniK data are defined
in [allowed storage resources](../modules/needed-storage/storage_for_each_armonik_data.tf).

# Set environment variables

You must set environment variables for deploying the storage resources. The main environment variables are:

```buildoutcfg
# Armonik storage namespace in the Kubernetes
export ARMONIK_STORAGE_NAMESPACE=<Your namespace in kubernetes>

# Directory path of the Redis certificates
export ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the Redis certificates>
    
# Name of Redis secret
export ARMONIK_STORAGE_REDIS_SECRET_NAME=<You kubernetes secret for the Redis>

# Directory path of the ActiveMQ credentials
export ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY=<Your directory path of the ActiveMQ credentials>
    
# Name of ActiveMQ secret
export ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME=<You kubernetes secret for the ActiveMQ>

# Directory path of the MongoDB credentials
export ARMONIK_STORAGE_MONGODB_CREDENTIALS_DIRECTORY=<Your directory path of the MongoDB credentials>

# Name of MongoDB secret
export ARMONIK_STORAGE_MONGODB_SECRET_NAME=<You kubernetes secret for the MongoDB>
```

**Mandatory:** To set these environment variables:

From the **root** of the repository, you source [file of environment variables](../utils/envvars-storage.conf).

```bash
   source infrastructure/utils/envvars-storage.conf
```

# Create a namespace for ArmoniK storage

**Mandatory:** Before deploring the ArmoniK storage resources, you must first create a namespace in the Kubernetes
cluster for ArmoniK storage:

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

Redis uses SSL/TLS support using certificates. In order to support TLS, Redis is configured with a X.509
certificate (`cert.crt`) and a private key (`cert.key`). In addition, it is necessary to specify a CA certificate bundle
file (`ca.crt`) or path to be used as a trusted root when validating certificates.

Execute the following command to create the Redis server secret in Kubernetes based on the certificates created and
saved in the directory `$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY`. In this project, we have certificates for test
in [credentials](../credentials) directory:

```bash
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key \
        --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt
```

## ActiveMQ server secret

ActiveMQ uses a file `jetty-realm.properties`. This is the file which stores user credentials and their roles in
ActiveMQ. It contains custom usernames and passwords and replace the file present by default inside the container.

In this project, we have a file of name `jetty-realm.properties` in [credentials](../credentials) directory:

```text
#username:password,[role-name]
admin:<ADMIN_PASSWD>,admin
user:<GUEST_PASSWD>,guest
```

Create a Kubernetes secret for the ActiveMQ server:

```bash
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties
```

## MongoDB server secret

MongoDB uses SSL/TLS support using certificates (`cert.pem`).

Execute the following command to create the MongoDB server secret in Kubernetes based on the certificates created and
saved in the directory `$ARMONIK_STORAGE_MONGODB_CREDENTIALS_DIRECTORY`. In this project, we have certificates for test
in [credentials](../credentials) directory:

```bash
kubectl create secret generic $ARMONIK_STORAGE_MONGODB_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=mongodb.pem=$ARMONIK_STORAGE_MONGODB_CREDENTIALS_DIRECTORY/cert.pem
```

# Create storages on Kubernetes

## Prepare the parameters file

Before deploying the storages, you must fist prepare a configuration file containing a list of the parameters of the
storages to be created.

**warning:** You have an example of [parameters.tfvars](parameters.tfvars).

The configuration has three components:

1. Kubernetes namespace where the storage will be created:

```terraform
# Namespace of ArmoniK storage
namespace = "armonik-storage"
```

2. List of storage to be created for each ArmoniK data:

```terraform
# Storage resources to be created
storage = ["MongoDB", "Amqp", "Redis"]
```

3. List of Kubernetes secrets of each storage to be created:

```terraform
# Kubernetes secrets for storage
storage_kubernetes_secrets = {
  mongodb  = "mongodb-storage-secret"
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
```

## Deploy

Position yourself in directory `infrastructure/storage/` and execute the following command to deploy storage:

```bash
make all CONFIG_FILE=<Your configuration file> 
```

You can also execute one of the following commands if you want to reuse the default configuration file:

```bash
make all CONFIG_FILE=global-parameters.tfvars 
```

or:

```bash
make all
```

The command `make all` executes three commands in the following order that you can execute separately:

* `make init`
* `make plan CONFIG_FILE=<Your configuration file>`
* `make apply CONFIG_FILE=<Your configuration file>`

After the deployment :

* an output file `./generated/output.conf` is generated containing the endpoint urls of the created storage (**Needed
  for ArmoniK deployment**) like:

```bash
MONGODB_URL="mongodb://192.168.1.13:31458"
REDIS_URL="192.168.1.13:30129"
ACTIVEMQ_HOST="192.168.1.13"
ACTIVEMQ_PORT="31392"
EXTERNAL_URL="192.168.1.13:30129"
```

* you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_STORAGE_NAMESPACE
```

## Clean-up

**If you want** to delete all storage resources deployed as services in Kubernetes, execute the command:

```bash
make destroy CONFIG_FILE=<Your configuration file> 
```

or, if you have used the default configuration file:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```
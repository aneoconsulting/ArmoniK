# Table of contents

1. [Introduction](#introduction)
2. [Set environment variables](#set-environment-variables)
3. [Create a namespace for ArmoniK storage](#create-a-namespace-for-armonik-storage)
4. [Create Kubernetes secrets](#create-kubernetes-secrets)
    1. [Redis storage secret](#redis-storage-secret)
    2. [ActiveMQ storage secret](#activemq-storage-secret)

# Introduction

Hereafter we present the creation of onpremise storage resources needed for ArmoniK on Kubernetes cluster.

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
```

**Mandatory:** To set these environment variables, for example:

1. position yourself in the [current directory](.).

2. copy the [template file](../../utils/envvars-storage.conf):

    ```bash
    cp  ../../envvars-storage.conf ./envvars.conf
    ```

3. modify the values of variables if needed in `./envvars.conf`

4. Source the file of configuration :

```bash
source ./envvars.conf
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

## Redis storage secret

Redis uses SSL/TLS support using certificates. In order to support TLS, Redis is configured with a X.509
certificate (`cert.crt`) and a private key (`cert.key`). In addition, it is necessary to specify a CA certificate bundle
file (`ca.crt`) or path to be used as a trusted root when validating certificates.

Execute the following command to create the Redis secret in Kubernetes based on the certificates created and saved in
the directory `$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY`. In this project, we have certificates for test
in [credentials](../../credentials) directory:

```bash
kubectl create secret generic $ARMONIK_STORAGE_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.crt \
        --from-file=key_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/cert.key \
        --from-file=ca_cert_file=$ARMONIK_STORAGE_REDIS_CERTIFICATES_DIRECTORY/ca.crt
```

## ActiveMQ storage secret

ActiveMQ use a file `jetty-realm.properties`. This is the file which stores user credentials and their roles in
ActiveMQ. It contains custom usernames and passwords and replace the file present by default inside the container.

Execute the following command to create the ActiveMQ storage secret in Kubernetes based on the `jetty-realm.properties`
created and saved in the directory `$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY`. In this project, we have a file of
name `jetty-realm.properties` in [credentials](../../credentials) directory:

```bash
kubectl create secret generic $ARMONIK_STORAGE_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_STORAGE_NAMESPACE \
        --from-file=$ARMONIK_STORAGE_ACTIVEMQ_CREDENTIALS_DIRECTORY/jetty-realm.properties
```
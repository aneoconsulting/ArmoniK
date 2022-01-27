# Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Set environment variables](#set-environment-variables)
- [Create a namespace for ArmoniK](#create-a-namespace-for-armonik)
- [Create Kubernetes secrets](#create-kubernetes-secrets)
  - [Redis secret](#redis-secret)
  - [ActiveMQ storage](#activemq-storage)
- [Prepare the parameters files](#prepare-the-parameters-files)
  - [Parameters for ArmoniK](#parameters-for-armonik)
  - [Parameters for storage](#parameters-for-storage)
  - [Parameters for monitoring](#parameters-for-monitoring)
- [Deploy](#deploy)
- [Clean-up](#clean-up)

# Introduction

This project presents the instructions to deploy ArmoniK in Kubernetes.

# Set environment variables

The project needs to define and set environment variables for deploying the infrastructure. The main environment
variables are:

```buildoutcfg
# Armonik namespace in the Kubernetes
export ARMONIK_NAMESPACE=<Your namespace in kubernetes>

# Armonik monitoring namespace in the Kubernetes
export ARMONIK_MONITORING_NAMESPACE=<Your namespace in kubernetes for monitoring ArmoniK>

# Directory path of the Redis certificates
export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the Redis certificates>
    
# Name of Redis secret
export ARMONIK_REDIS_SECRET_NAME=<You kubernetes secret for the Redis storage>

# Directory path of the certificates of external Redis
export ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY=<Your directory path of the certificates of external Redis>
    
# Name of secret of external Redis
export ARMONIK_EXTERNAL_REDIS_SECRET_NAME=<You kubernetes secret for the external Redis storage>

# Directory path of the ActiveMQ credentials
export ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY=<Your directory path of the ActiveMQ credentials>
    
# Name of ActiveMQ secret
export ARMONIK_ACTIVEMQ_SECRET_NAME=<You kubernetes secret for the ActiveMQ storage>
```

**Mandatory:** To set these environment variables:

From the **root** of the repository source [file of environment variables](../../utils/envvars.conf).

2. copy the [template file](../utils/envvars-armonik.conf):

   ```bash
   cp ../utils/envvars-armonik.conf ./envvars.conf
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
kubectl create namespace $ARMONIK_MONITORING_NAMESPACE
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

Execute the following command to create the Redis client secrets (Redis for ArmoniK and external Redis used by HTC Mock
smaple) in Kubernetes. In this project, we have certificates for test in [credentials](../credentials) directory. Create
a Kubernetes secret for Redis client:

```bash
kubectl create secret generic $ARMONIK_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_cert_file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=certificate_pfx=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
        
kubectl create secret generic $ARMONIK_EXTERNAL_REDIS_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=ca_cert_file=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=certificate_pfx=$ARMONIK_EXTERNAL_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
```

## ActiveMQ storage

ActiveMQ client use a file `amqp-credentials.json`. This is the file which stores user credentials.

In this project, we have a file of name `amqp-credentials.json` in [credentials](../credentials ) directory:

```json
{
  "Amqp": {
    "User": "user",
    "Password": "<GUEST_PASSWD>"
  }
}
```

Create a Kubernetes secret for the ActiveMQ client:

```bash
kubectl create secret generic $ARMONIK_ACTIVEMQ_SECRET_NAME \
        --namespace=$ARMONIK_NAMESPACE \
        --from-file=amqp_credentials=$ARMONIK_ACTIVEMQ_CREDENTIALS_DIRECTORY/amqp-credentials.json
```

# Prepare the parameters files

Before deploying the ArmoniK components, you must fist prepare the configuration files containing a list of the
parameters.

## Parameters for ArmoniK

The parameters file for `ArmoniK` components are defined in [armonik-parameters.tfvars](./armonik-parameters.tfvars) and
they are as follows (you can modify/update them):

1. Kubernetes namespace where ArmoniK's components will be created:

```terraform
namespace = "armonik"
```

2. Level of logging

```terraform
logging_level = "Information"
```

3. Information for **ArmoniK control plane**:

```terraform
control_plane = {
  replicas          = 1
  image             = "dockerhubaneo/armonik_control"
  tag               = "0.2.0"
  image_pull_policy = "IfNotPresent"
  port              = 5001
}
```

4. Information for **ArmoniK compute plane** which is composed of a container of `polling agent` and container(s)
   of `worker(s)`:

```terraform
compute_plane = {
  # number of replicas for each deployment of compute plane
  replicas      = 1
  # number of queues according to priority of tasks
  max_priority  = 1
  # ArmoniK polling agent
  polling_agent = {
    image             = "dockerhubaneo/armonik_pollingagent"
    tag               = "0.2.0"
    image_pull_policy = "IfNotPresent"
    limits            = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests          = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  # ArmoniK workers
  worker        = [
    {
      name              = "worker"
      port              = 80
      # [Default]
      image             = "dockerhubaneo/armonik_worker_dll"
      tag               = "0.1.1"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "920m"
        memory = "2048Mi"
      }
      requests          = {
        cpu    = "50m"
        memory = "100Mi"
      }
    }
  ]
}
```

## Parameters for storage

The parameters file for `Storage` [storage-parameters.tfvars](./storage-parameters.tfvars) contains the types of storage
for each ArmoniK data type, the endpoint urls and Kubernetes secrets of these storages. The parameters are defined as
follows, and you must update them especially the endpoint urls:

1. List of storage for each ArmoniK data:

```terraform
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  # shared = "NFS" if you use an onpremise cluster
  shared         = "HostPath"
  # Mandatory: If you want execute the HTC Mock sample, you must set this parameter to "Redis", otherwise let it to ""
  external       = "Redis"
}
```

`external` storage is a parameter to choose un external storage for data client. By default, it is set to empty
string `""`, but for **HTC Mock sample** you must set it to `"Redis"`.

**Warning:** The list of storage adapted to each ArmoniK data type are defined
in [Adapted storage for ArmoniK](../modules/needed-storage/storage_for_each_armonik_data.tf).

2. List of endpoint urls and credentials for each needed storage that **YOU MUST MODIFY**:

```terraform
storage_endpoint_url = {
  mongodb  = {
    url    = "mongodb://192.168.1.13:32670"
    secret = ""
  }
  redis    = {
    url    = "192.168.1.13:32041"
    secret = "redis-storage-secret"
  }
  activemq = {
    host   = "192.168.1.13"
    port   = "30423"
    secret = "activemq-storage-secret"
  }
  shared   = {
    # host = "<NFS_SERVER_IP>" if you use an onpremise cluster
    host   = ""
    secret = ""
    # Path to external shared storage from which worker containers upload .dll
    path   = "/data"
  }
  external = {
    url    = "192.168.1.13:32041"
    secret = "external-redis-storage-secret"
  }
}
```

## Parameters for monitoring

The parameters file for `Monitoring` [monitoring-parameters.tfvars](./monitoring-parameters.tfvars) contains the list of
monitoring tools that we want to activate:

```terraform
monitoring = {
  namespace  = "armonik-monitoring"
  seq        = true
  grafana    = true
  prometheus = true
  dashboard  = false
}
```

# Deploy

Position yourself in directory `infrastructure/armonik` and execute the following command to deploy ArmoniK:

```bash
make all ARMONIK_PARAMETERS_FILE=armonik-parameters.tfvars \
         STORAGE_PARAMETERS_FILE=storage-parameters.tfvars \
         MONITORING_PARAMETERS_FILE=monitoring-parameters.tfvars 
```

or:

```bash
make all
```

After the deployment you can display the list of created resources in Kubernetes as follows:

```bash
kubectl get all -n $ARMONIK_NAMESPACE
```

# Clean-up

**If you want** to delete all ArmoniK resources deployed as services in Kubernetes, execute the command:

```bash
make destroy ARMONIK_PARAMETERS_FILE=armonik-parameters.tfvars \
             STORAGE_PARAMETERS_FILE=storage-parameters.tfvars \
             MONITORING_PARAMETERS_FILE=monitoring-parameters.tfvars
```

or, if you have used the default configuration file:

```bash
make destroy
```

**If you want** to delete generated files too, execute the command:

```bash
make clean
```
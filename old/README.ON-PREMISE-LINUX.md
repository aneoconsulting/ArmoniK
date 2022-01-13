# Table of contents

1. [Install Kubernetes on local machine](#install-kubernetes-on-local-machine)
2. [Configure the environment](#configure-the-environment)
3. [Create secrets in Kubernetes](#create-secrets-in-kubernetes)
    1. [Secrets for Redis](#secrets-for-redis)
4. [Build Armonik artifacts](#build-armonik-artifacts)
    1. [Build Armonik artifacts on local](#build-armonik-artifacts-on-local)
    2. [Build client/server artifacts on local](#build-client-/-server-artifacts-on-local)
    3. [Build Armonik API](#build-armonik-api)
5. [Deploy Armonik resources](#deploy-armonik-resources)
6. [Running an example application](#running-an-example-application)
7. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

# Install Kubernetes on local machine <a name="install-kubernetes-on-local-machine"></a>

Instructions to install Kubernetes on local Linux machine.

You can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/) on Linux OS.

Install K3s as follows:

```bash
curl -sfL https://get.k3s.io | sh -
```

If you want use host's Docker rather than containerd use `--docker` option:

```bash
curl -sfL https://get.k3s.io | sh -s - --docker
```

Then initialize the configuration file of Kubernetes:

```bash
sudo chmod 755 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

**Warning**: Hereafter we will use the installation of K3s with `--docker` option. This allows K3s access local docker
images directly (without using 'docker save').

To uninstall K3s, use the following command:

```bash
/usr/local/bin/k3s-uninstall.sh
```

# Configure the environment <a name="configure-the-environment"></a>

The project needs to define and set environment variables for building the binaries and deploying the infrastructure.
The main environment variables are:

```buildoutcfg
# To simplify the installation it is suggested that
# a unique <ARMONIK_TAG> name is used to prefix the
# different required resources.
ARMONIK_TAG=<Your tag>

# Define the type of the database service
ARMONIK_TASKS_TABLE_SERVICE=<Your database type>

# Define the type of the message queue
ARMONIK_QUEUE_SERVICE=<Your message queue type>

# Define an environment variable to select API Gateway service.
ARMONIK_API_GATEWAY_SERVICE=<Your API gateway type>

# Define type of the environment
# It can be (the list is not exhaustive):
# local
# cluster-on-aws
# cloud
export ARMONIK_CLUSTER_CONFIG=<Your environment type>

# Define the image pull policy in Kubernetes
export ARMONIK_IMAGE_PULL_POLICY=<Your image pull policy>

# Define an environment variable containing the path to
# the local nuget repository.
ARMONIK_NUGET_REPOS=<Your NuGet repository>

# Define an environment variable containing the path to
# the redis credentials.
ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<Your path to Redis certificates>

# Redis secrets in Kubernetes
export ARMONIK_REDIS_SECRETS=<Your Redis secrets name in Kubernetes>

# Name of your client/server sample
export ARMONIK_APPLICATION_NAME=<Your client/server sample's name>

# Define an environment variable containing the docker registry
# if it exists, otherwise initialize the variable to empty.
ARMONIK_DOCKER_REGISTRY=<Your Docker registry>
```

**Mandatory:** To set these environment variables:

1. Copy the [template file for Linux](configure/onpremise-linux-config.conf) and modify the values of variables if
   needed:

```bash
cp configure/onpremise-linux-config.conf ./envvars.conf
```

2. Source the file of configuration:

```bash
source ./envvars.conf
```

# Create secrets in Kubernetes <a name="create-secrets-in-kubernetes"></a>

## Secrets for Redis <a name="secrets-for-redis"></a>

Hereafter, Redis uses SSL/TLS support using certificates. In order to support TLS, Redis is configured with a X.509
certificate (`redis.crt`) and a private key (`redis.key`). In addition, it is necessary to specify a CA certificate
bundle file (`ca.crt`) or path to be used as a trusted root when validating certificates. A SSL certificate of
type `PFX` is also used (`certificate.pfx`).

Execute the following command to create Redis secrets in Kubernetes based on the certificates created and saved in the
directory `$ARMONIK_REDIS_CERTIFICATES_DIRECTORY`:

```bash
kubectl create secret generic $ARMONIK_REDIS_SECRETS \
        --from-file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/redis.crt \
        --from-file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/redis.key \
        --from-file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/ca.crt \
        --from-file=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY/certificate.pfx
```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>

## Build Armonik artifacts on local <a name="build-armonik-artifacts-on-local"></a>

Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install all Armonik, in `<project_root>`:

1. Set the name of your sample (Optional):

```bash
export ARMONIK_APPLICATION_NAME=<Name of your sample>
```

2. in the project there is a default sample of name `ArmonikSamples`, then you build as follows:

```bash
make all
```

To build with your own sample:

```bash
make all ARMONIK_APPLICATION_NAME=<Name of your sample>
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following two files:

* `local_dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
* `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

### Debug mode

To build in `debug` mode, you execute this command:

```bash
make all BUILD_TYPE=Debug ARMONIK_APPLICATION_NAME=<Name of your sample>
```

replace the name of the sample application.

For more information see [here](./docs/debug.md)

## Build client/server artifacts on local <a name="build-client-/-server-artifacts-on-local"></a>

To build only the sample application in `<project_root>`:

```bash
make sample-app ARMONIK_APPLICATION_NAME=<Name of your sample>
```

replace the name of the sample application.

## Build Armonik API <a name="build-armonik-api"></a>

To build only Armonik API in `<project_root>`:

```bash
make build-armonik-api
```

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>

1. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-local-deployment
   ```

2. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime
   ```

# Running an example application <a name="running-an-application-workload"></a>

In the folder [applications/ArmonikSamples](./applications/ArmonikSamples), you will find the code of the .NET 5.0
Armonik samples.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job and the
grid are implemented by a client in folder [applications/ArmonikSamples/Client](./applications/ArmonikSamples/Client).

1. Export the location of the client config file. The config is passed this way for ArmonikSamples and HtcMock. This may be different for your application.
   ```bash
   export CLIENT_CONFIG_FILE=generated/Client_config.json
   ```

2. Run your application
   ```
   dotnet generated/$ARMONIK_APPLICATION_NAME/Client/Client.dll
   ```

# Clean and destroy Armonik resources <a name="clean-and-destroy-armonik-resources"></a>

In the root forlder `<project_root>`, to destroy all Armonik resources deployed on the local machine, execute the
following commands:

1. Destroy all Armonik resources:
   ```bash
   make destroy-dotnet-local-runtime
   ```

2. Clean Terraform project:
   ```bash
   make clean-grid-local-deployment
   ```

3. Clean binaries and generated files:
   ```bash
   make clean-grid-local-project
   ```

4. **If you want** uninstall Kubernetes on the local machine:
   ```bash
   /usr/local/bin/k3s-uninstall.sh
   ```

5. If you want remove local docker images with tag of `ARMONIK_TAG` environment variable:
   ```bash
   docker rmi -f $(docker image ls --format="{{json .}}" | jq "select( (.Tag==\"$ARMONIK_TAG\") ) .ID" | tr -d \")
   ```
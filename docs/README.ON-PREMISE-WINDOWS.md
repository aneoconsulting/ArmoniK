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
Instructions to install Kubernetes on local Windows machine. You can use WSL 2.

### Windows Subsystem for Linux Installation Guide for Windows 10
The manual installation steps for WSL are listed below and can be used to install Linux on any version of Windows 10.

#### Step 1 : Enable the Windows Subsystem for Linux

You must first enable the "Windows Subsystem for Linux" optional feature before installing any Linux distributions on Windows.
Open PowerShell as Administrator and run:

```bash
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```
#### Step 2 : Enable Virtual Machine feature

Before installing WSL 2, you must enable the Virtual Machine Platform optional feature. Your machine will require virtualization capabilities to use this feature.

Open PowerShell as Administrator and run:

```bash
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
Restart your machine to complete the WSL install and update to WSL 2.

#### Step 3 : Download and Install Docker on Windows

1. Go to the website https://docs.docker.com/docker-for-windows/install/ and download the docker file.
2. Then, double-click on the Docker Desktop Installer.exe to run the installer.
3. After completion of the installation process, click Close and restart.

#### Step 4 : Download the Linux kernel update package

1. Download the latest package:
     * WSL2 Linux kernel update package for x64 machines
2. Run the update package downloaded in the previous step. (Double-click to run - you will be prompted for elevated permissions, select `yes` to approve this installation.)

Once the installation is complete, move on to the next step - setting WSL 2 as your default version when installing new Linux distributions.

#### Step 5 : Set WSL 2 as your default version

Open PowerShell and run this command to set WSL 2 as the default version when installing a new Linux distribution:

```bash
wsl --set-default-version 2
```

#### Step 6 : Install your Linux distribution of choice
1. Open the Microsoft Store and select your favorite Linux distribution (preferably Ubuntu 20.04 LTS).
2. From the distribution's page, select "Get".
The first time you launch a newly installed Linux distribution, a console window will open and you'll be asked to wait for a minute or two for files to de-compress and be stored on your PC. All future launches should take less than a second.

You will then need to create a user account and password for your new Linux distribution.

#### Step 7 : WSL Integration on Docker
Configure which WSL 2 distros you want to access Docker from.
**Docker** -> **Settings** -> **Resources** -> **WSL INTEGRATION** :
1. Enable integration with my default WSL distro
2. Enable integration with additional distros: Ubuntu-20.04
3. Apply & Restart

#### Step 8 : Kubernets on Docker
**Docker** -> **Settings** -> **kubernetes**
1. Enable Kubernetes
2. Apply & Restart

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
# cluster
# cloud
export ARMONIK_CLUSTER_CONFIG=<Your environment type>

# Define the image pull policy in Kubernetes
export ARMONIK_IMAGE_PULL_POLICY=<Your image pull policy>

# Define an environment variable containing the path to
# the local nuget repository.
ARMONIK_NUGET_REPOS=<Your NuGet repository>

# Define an environment variable containing the path to
# the redis certificates.
ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<Your path to Redis certificates>

# Redis secrets in Kubernetes
export ARMONIK_REDIS_SECRETS=<Your Redis secrets name in Kubernetes>

# Define an environment variable containing the docker registry
# if it exists, otherwise initialize the variable to empty.
ARMONIK_DOCKER_REGISTRY=<Your Docker registry>
```

**Mandatory:** To set these environment variables:
1. Copy the [template file for WSL on Windows](configure/onpremise-wsl-config.conf) and modify the values of variables if needed:
```bash
cp configure/onpremise-wsl-config.conf ./envvars.conf
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
1. Set the name of your sample:
```bash
export ARMONIK_APPLICATION_NAME=<Name of your sample>
```
2. then build:
```bash
make all
```
or you can build in one command:
```bash
make all ARMONIK_APPLICATION_NAME=<Name of your sample>
```
for example in the project there is a sample of name `ArmonikSamples`:
```bash
make all ARMONIK_APPLICATION_NAME=ArmonikSamples
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
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

2. You need to execute `armonik/configure/bootstrap.sh` to mount `/redis_certificates`.
```bash
cd configure
./bootstrap.sh

```

3. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime
   ```

# Running an example application <a name="running-an-application-workload"></a>
In the folder [applications/ArmonikSamples](./applications/ArmonikSamples), you will find the code of the .NET 5.0 Armonik samples.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job and the grid are implemented by a client in folder [applications/ArmonikSamples/Client](./applications/ArmonikSamples/Client).

1. Create a sample Kubernetes job `local-single-task-dotnet5.0.yaml` as follows:
   ```bash
   make k8s-jobs
   ```

2. Run the following command to launch a kubernetes job:
   ```bash
   kubectl apply -f ./generated/local-single-task-dotnet5.0.yaml
   ```

3. look at the log of the submission:
   ```bash
   kubectl logs job/single-task -f
   ```

4. To clean the job submission instance:
   ```bash
   kubectl delete -f ./generated/local-single-task-dotnet5.0.yaml
   ```

# Clean and destroy Armonik resources <a name="clean-and-destroy-armonik-resources"></a>
In the root forlder `<project_root>`, to destroy all Armonik resources deployed on the local machine, execute the following commands:

1. Delete the launched Kubernetes job, example:
```bash
kubectl delete -f ./generated/local-single-task-dotnet5.0.yaml
```

2. Destroy all Armonik resources:
```bash
make destroy-dotnet-local-runtime
```

3. Clean Terraform project, binaries and generated files:
```bash
make clean-grid-local-project
```

4. If you want remove local docker images with tag of `ARMONIK_TAG` environment variable:
```bash
docker rmi -f $(docker image ls --format="{{json .}}" | jq "select( (.Tag==\"$ARMONIK_TAG\") ) .ID" | tr -d \")
```
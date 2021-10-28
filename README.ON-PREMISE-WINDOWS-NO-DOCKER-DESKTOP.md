1. [Install Kubernetes on local machine](#install-kubernetes-on-local-machine)
2. [Configure the environment](#configure-the-environment)
3. [Build Armonik artifacts](#build-armonik-artifacts)
   1. [Build Armonik artifacts on local](#build-armonik-artifacts-on-local)
   2. [Use built Armonik artifacts from a Docker registry](#use-built-armonik-artifacts-from-a-docker-registry)
4. [Get Armonik artifacts from DockerHub](#get-armonik-artifacts-from-dockerhub)
5. [Deploy Armonik resources](#deploy-armonik-resources)
6. [Running an example application](#running-an-example-application)
7. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

# Install and configure WSL2 <a name="install-and-configure-wsl2"></a>

## Install WSL2

The manual installation steps for WSL are listed below and can be used to install Linux on any version of Windows 10.

### Step 1 : Enable the Windows Subsystem for Linux

You must first enable the "Windows Subsystem for Linux" optional feature before installing any Linux distributions on Windows.
Open PowerShell as Administrator and run:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```
### Step 2 : Enable Virtual Machine feature

Before installing WSL 2, you must enable the Virtual Machine Platform optional feature. Your machine will require virtualization capabilities to use this feature.

Open PowerShell as Administrator and run:

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
Restart your machine to complete the WSL install and update to WSL 2.

### Step 3 : Download the Linux kernel update package

1. Download the latest package:
     * WSL2 Linux kernel update package for x64 machines
2. Run the update package downloaded in the previous step. (Double-click to run - you will be prompted for elevated permissions, select `yes` to approve this installation.)

Once the installation is complete, move on to the next step - setting WSL 2 as your default version when installing new Linux distributions.

### Step 4 : Set WSL 2 as your default version

Open PowerShell and run this command to set WSL 2 as the default version when installing a new Linux distribution:

```powershell
wsl --set-default-version 2
```

### Step 5 : Install your Linux distribution of choice
1. Open the Microsoft Store and select your favorite Linux distribution (preferably Ubuntu 20.04 LTS).
2. From the distribution's page, select "Get".
The first time you launch a newly installed Linux distribution, a console window will open and you'll be asked to wait for a minute or two for files to de-compress and be stored on your PC. All future launches should take less than a second.

You will then need to create a user account and password for your new Linux distribution.

## Enable SystemD on WSL with Genie

Kubernetes (and docker) needs SystemD to work. For this, you need to install [Genie](https://github.com/arkane-systems/genie).

### Install Genie

Within WSL

```bash
cd /tmp
wget --content-disposition "https://gist.githubusercontent.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950/raw/952347f805045ba0e6ef7868b18f4a9a8dd2e47a/install-sg.sh"
chmod +x install-sg.sh
./install-sg.sh
rm install-sg.sh
```

If ever you did not install Ubuntu 20.04, you would need to modify `install-sg.sh` and change `UBUNTU_VERSION` before `.install-sg.sh`.

Then within Powershell:

```powershell
wsl --shutdown
wsl genie -s
```

It will most likely timeout on some services.
You would need to disable those.


```bash
sudo systemctl disable getty@tty1.service multipathd.service multipathd.socket ssh.service
sudo systemctl mask systemd-remount-fs.service
```

### Start a Genie session

Now that Genie is installed, you need to run `wsl genie -s` to start a session.
The first session started will launch Genie and create a dedicated namespace (this should take a few seconds).
Then, all sessions started with `wsl genie -s` will live in that namespace, where systemD is running, as PID 1.

Starting a session with `wsl` alone will not create the session within the Genie namespace, and thus services like docker or kubernetes will not behave as expected.

### Configure Genie

You can adjust the configuration of Genie in the file `/etc/genie.ini`.

If you want to have access to Windows tools from within Genie (like `code`), you have to set `clone-path` to `true`.
On Ubuntu 20.04, the path might not be set properly, even with `clone-path=true`.
In that case, you would to add the following command to your `.bashrc`:

```bash
# This is a temporary hack until the following bug is fixed:
# https://github.com/arkane-systems/genie/issues/201
if [ "${INSIDE_GENIE:-0}" != 0 ] \
    && cat /etc/genie.ini | grep --quiet '^clone-path=true' \
    && ! echo "$PATH" | grep --quiet '/WINDOWS/system32' \
    && [ -f /run/genie.path ]
then
    echo "[DEBUG] Add content of '/run/genie.path' to PATH."
    PATH="$PATH:$(cat /run/genie.path)"
fi
```

# Install dependencies <a name="install-dependencies"></a>

## Prerequesites

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release
```

## virtualenv

```bash
sudo apt install python3-pip
sudo pip3 install --no-cache virtualenv
```

## Docker

The procedure to install Docker: https://docs.docker.com/engine/install/ubuntu/

TL;DR:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Kubernetes

The procedure to install Kubernetes: https://rancher.com/docs/k3s/latest/en/installation/install-options/

TL;DR:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

To uninstall kubernetes: `/usr/local/bin/k3s-uninstall.sh`

## Terraform

The procedure to install Terraform: https://www.terraform.io/docs/cli/install/apt.html

TL;DR:

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform
```

## Helm

The procedure to install Helm: https://helm.sh/docs/intro/install/#from-apt-debianubuntu

TL;DR:

```bash
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## dotnet

The procedure to install DotNet: https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#2004-

TL;DR:

```bash
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update; \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-5.0
```

# Setup the project <a name="setup-the-project"></a>
## Virtualenv

Inside the project folder.

```bash
virtualenv --python=python3.8 venv
source ./venv/bin/activate
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

# Define an environment variable containing the docker registry
# if it exists, otherwise initialize the variable to empty.
ARMONIK_DOCKER_REGISTRY=<Your Docker registry>
```

**Mandatory:** To set these environment variables:
1. Copy the [template file for WSL](configure/onpremise-linux-config.conf) and modify the values of variables if needed:
```bash
cp configure/onpremise-linux-config.conf ./envvars.conf
```

2. Source the file of configuration:
```bash
source ./envvars.conf
```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
## Build Armonik artifacts on local <a name="build-armonik-artifacts-on-local"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `<project_root>`:
```bash
make build-all-infra
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `local_dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

To build only the sample application in `<project_root>`:
```bash
make sample-app
```
To build only the sample application in `<project_root>` with all its dotnet dependencies (API, core packages):
```bash
make armonik-full
```

## Select the sample application to build

The selection of the sample to compile is made via the variable `ARMONIK_APPLICATION_NAME`.
It can be added in the configuration file with, for instance :
```bash
export ARMONIK_APPLICATION_NAME=ArmonikSamples
```
This is its default value.
It can also be passed to the different make commands such as :
```bash
make sample-app ARMONIK_APPLICATION_NAME=ArmonikSamples
```
or
```bash
make all ARMONIK_APPLICATION_NAME=ArmonikSamples
```

### Debug mode
To build in `debug` mode, you execute this command:
```bash
make all BUILD_TYPE=Debug
```

For more information see [here](./docs/debug.md)

## Use built Armonik artifacts from a Docker registry<a name="use-built-armonik-artifacts-from-a-docker-registry"></a>

1. Generate the file of parameters for Terraform deployment `local_dotnet5.0_runtime_grid_config.json` . In the root of the project `<project_root>`:
```bash
make app-configs
```

2. Create a sample Kubernetes job `local-single-task-dotnet5.0.yaml` as follows:
```bash
  make k8s-jobs
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

# Running an example application <a name="running-an-example-application"></a>
In the folder [applications/ArmonikSamples](./applications/ArmonikSamples), you will find the code of the .NET 5.0 Armonik samples.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job and the grid are implemented by a client in folder [applications/ArmonikSamples/Client](./applications/ArmonikSamples/Client).

1. Run the following command to launch a kubernetes job:
   ```bash
   kubectl apply -f ./generated/local-single-task-dotnet5.0.yaml
   ```

2. look at the log of the submission:
   ```bash
   kubectl logs job/single-task -f
   ```

3. To clean the job submission instance:
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

4. **If you want** uninstall Kubernetes on the local machine:
```bash
/usr/local/bin/k3s-uninstall.sh
```

5. **If you want remove ALL** local docker images:
```bash
docker rmi -f $(docker images -a -q)
```
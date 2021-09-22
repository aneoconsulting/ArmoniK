# Table of contents
1. [Install Kubernetes on local machine](#install-kubernetes-on-local-machine)
   1. [On Linux](#on-linux)
   2. [On Windows](#on-windows)
2. [Configure the environment](#configure-the-environment) 
3. [Kubernetes configuration](#kubernetes-configuration)  
4. [Build Armonik artifacts](#build-armonik-artifacts)
5. [Deploy Armonik resources](#deploy-armonik-resources)
6. [Running an example workload](#running-an-example-workload)
7. [Destroy Armonik resources](#destroy-armonik-resources)

# Install Kubernetes on local machine <a name="install-kubernetes-on-local-machine"></a>
Instructions to install Kubernetes on local Linux or Windows machine.

## On Linux <a name="on-linux"></a>
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
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

**Warning**: Hereafter we will use the installation of K3s with `--docker` option. This allows K3s access local docker images directly (without using 'docker save').

To uninstall K3s, use the following command:
```bash
/usr/local/bin/k3s-uninstall.sh
```

## On Windows <a name="on-windows"></a>
You can use WSL 2.

### Windows Subsystem for Linux Installation Guide for Windows 10
The manual install steps for WSL are listed below and can be used to install Linux on any version of Windows 10.

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
Define variables for deploying the infrastructure as follows:
1. To simplify this installation it is suggested that a unique <TAG> name (to be used later) is also used to prefix the
   different required resources.
   ```bash
      export ARMONIK_TAG=<Your tag>
   ```

2. Define the type of the database service
   ```bash
      export ARMONIK_TASKS_TABLE_SERVICE=<Your DB service>
   ```
   `<Your DB service>` can be (the list is not exhaustive)
   - `DynamoDB`
   - `MongoDB`

3. Define an environment variable containing the path to the local nuget repository.
   ```bash
      export ARMONIK_NUGET_REPOS=<project directory>/dist/dotnet5.0
   ```

4. Define an environment variable containing the path to the redis certificates.
   ```bash
      export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<redis certificates directory path>
   ```

5. Define an environment variable containing the docker registry if it exists, otherwise initialize the variable to empty.
   ```bash
      export ARMONIK_DOCKER_REGISTRY=<docker registry>
   ```

# Kubernetes configuration <a name="kubernetes-configuration"></a>
**On Windows** You need to execute `Armonika/script_config_os/check_OS.sh` to configure Kubernetes.
```bash
cd scropt_config_os
./check_OS.sh
cd ..
```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `<project_root>`:
```bash
make dotnet50-path TAG=$ARMONIK_TAG TASKS_TABLE_SERVICE=$ARMONIK_TASKS_TABLE_SERVICE REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. Create needed credentials (on-premises): for the on-premises deployment, some credentials are needed to
   be defined by the user. Run the following command to create mock credentials needed for the Armonik agents
   (indeed AWS Dynamodb and AWS SQS are emulated in localstack on-premises):
   ```bash
   kubectl create secret generic htc-agent-secret-mock --from-literal='AWS_ACCESS_KEY_ID=mock_secret_key' --from-literal='AWS_SECRET_ACCESS_KEY=mock_secret_key'
   ```

2. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-local-deployment TAG=$ARMONIK_TAG
   ```
3. **On Windows** You need to execute `Armonika/configure/bootstrap.sh` to mount `/redis_certificates`.
```bash
cd configure
./bootstrap.sh
cd ..
```

4. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime TAG=$ARMONIK_TAG REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
   ```

# Running an example workload <a name="running-an-example-workload"></a>
In the folder [mock_computation](./examples/workloads/dotnet5.0/mock_computation), you will find the code of the
.NET 5.0 program mocking computation.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job
and the grid are implemented by a client in folder [./examples/client/python](./examples/client/python).

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
   kubectl delete -f ./generated/single-task-test.yaml
   ```

# Destroy Armonik resources <a name="destroy-armonik-resources"></a>
In the root forlder `<project_root>`, to destroy all Armonik resources deploy on the local machine, execute the following command:
```bash
make destroy-dotnet-local-runtime TAG=$ARMONIK_TAG REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
```
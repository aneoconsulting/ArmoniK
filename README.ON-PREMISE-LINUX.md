# Table of contents
1. [Install Kubernetes on local machine](#install-kubernetes-on-local-machine)
2. [Configure the environment](#configure-the-environment)
   1. [Environment variables](#environment-variables)
   2. [Python environment](#python-environment)
3. [Build Armonik artifacts](#build-armonik-artifacts)
4. [Deploy Armonik resources](#deploy-armonik-resources)
5. [Running an example workload](#running-an-example-workload)
6. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

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

**Warning**: Hereafter we will use the installation of K3s with `--docker` option. This allows K3s access local docker images directly (without using 'docker save').

To uninstall K3s, use the following command:
```bash
/usr/local/bin/k3s-uninstall.sh
```

# Configure the environment <a name="configure-the-environment"></a>
## Environment variables <a name="environment-variables"></a>
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

**To set these environment variables**, execute the following command:
```bash
./configurations/set-envvars.sh LINUX
```

## Python environment <a name="python-environment"></a>
The current release of Armonik requires python3 in the PATH of your system, and the documentation assumes the use of *virtualenv*. 

Set up this as follows (for example python3.7):
```bash
virtualenv --python=python3.7 venv
```

When successful :
```bash
created virtual environment CPython3.7.10.final.0-64 in 1329ms
  creator CPython3Posix(dest=<project_roor>/venv, clear=False, no_vcs_ignore=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/Users/user/Library/Application Support/virtualenv)
    added seed packages: pip==21.0.1, setuptools==54.1.2, wheel==0.36.2
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator
```

Check you have the correct version of python (`3.7.x`), with a path rooted on `<project_root>`, 
then start the environment:
```
source ./venv/bin/activate
```

Check the python version as follows:
```bash
$ which python
<project_root>/venv/bin/python
$ python -V
Python 3.7.10
```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `<project_root>`:
```bash
make dotnet50-path
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

## Debug mode
To build in `debug` mode, you execute this command:
```bash
make dotnet50-path BUILD_TYPE=Debug
```

For more information see [here](./docs/debug.md)

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-local-deployment
   ```

2. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime
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

5. **If you want** remove all local docker images:
```bash
docker rmi -f $(docker images -a -q)
```
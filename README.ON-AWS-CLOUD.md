# Table of contents
1. [Configure the environment](#configure-the-environment)
   1. [Configure AWS Cli](#configure-aws-cli)
   2. [Environment variables](#environment-variables)
   3. [ECR authentication](#ecr-authentication)
   4. [Python environment](#python-environment)
2. [Build Armonik artifacts](#build-armonik-artifacts)
3. [Deploy Armonik resources](#deploy-armonik-resources)
4. [Running an example workload](#running-an-example-workload)

# Configure the environment <a name="configure-the-environment"></a>
## Configure AWS Cli <a name="configure-aws-cli"></a>

You need to provide your AWS secret credentials.
```bash
   aws configure
```

## Environment variables <a name="environment-variables"></a>
The project needs to define and set environment variables for building the binaries and deploying the infrastructure.
The main environment variables are:
```buildoutcfg
# To simplify the installation it is suggested that
# a unique <ARMONIK_TAG> name is used to prefix the
# different required resources.
ARMONIK_TAG=<Your tag>

# Define the region where the grid will be deployed
export ARMONIK_REGION=<Your AWS region>

# Define the type of the database service
ARMONIK_TASKS_TABLE_SERVICE=<Your database type>

# Define the type of the message queue
ARMONIK_QUEUE_SERVICE=<Your message queue type>

# Define an environment variable to select API Gateway service.
ARMONIK_API_GATEWAY_SERVICE=<Your API gateway type>

# Define the AWS account ID where the grid will be deployed
export ARMONIK_ACCOUNT_ID=<Your AWS account ID>

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
./configurations/set-envvars.sh AWS
```

## ECR authentication <a name="ecr-authentication"></a>
As you'll be uploading images to ECR, to avoid timeouts, refresh your ECR authentication token:
```bash
aws ecr get-login-password --region $ARMONIK_REGION | docker login --username AWS --password-stdin $ARMONIK_ACCOUNT_ID.dkr.ecr.$ARMONIK_REGION.amazonaws.com
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
make dotnet50-path REGION=$ARMONIK_REGION
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following 
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. Create S3 buckets. The following step creates the S3 buckets and an encryption key that will be needed during the installation:
   ```bash
   make init-grid-state REGION=$ARMONIK_REGION

   ```

2. Run the following to initialize the Terraform environment: 
   ```bash
   make init-grid-deployment REGION=$ARMONIK_REGION
   ```
   
3. If successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-runtime REGION=$ARMONIK_REGION
   ```
   
# Running an example workload <a name="running-an-example-workload"></a>
In the folder [mock_computation](./examples/workloads/dotnet5.0/mock_computation), you will find the code of the
.NET 5.0 program mocking computation. 

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job
and the grid are implemented by a client in folder [./examples/client/python](./examples/client/python).

1. Run the following command to launch a kubernetes job:
   ```bash
   kubectl apply -f ./generated/single-task-dotnet5.0.yaml
   ```
   
2. look at the log of the submission:
   ```bash
   kubectl logs job/single-task -f
   ```
   
3. To clean the job submission instance:
   ```bash
   kubectl delete -f ./generated/single-task-dotnet5.0.yaml
   ```

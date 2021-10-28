# Table of contents
1. [Configure the environment](#configure-the-environment)
   1. [Configure AWS Cli](#configure-aws-cli)
   2. [Environment variables](#environment-variables)
   3. [ECR authentication](#ecr-authentication)
2. [Build Armonik artifacts](#build-armonik-artifacts)
3. [Deploy Armonik resources](#deploy-armonik-resources)
4. [Running an example application](#running-an-example-application)

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

# Define type of the environment
# It can be (the list is not exhaustive):
# local
# cluster
# cloud
export ARMONIK_CLUSTER_CONFIG=<Your environment type>

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

**Mandatory:** To set these environment variables:
1. Copy the [template file for AWS](configure/onpremise-aws-config.conf) and modify the values of variables if needed:
```bash
cp configure/aws-config.conf ./envvars.conf
```

2. Source the file of configuration:
```bash
source ./envvars.conf
```

## ECR authentication <a name="ecr-authentication"></a>
As you'll be uploading images to ECR, to avoid timeouts, refresh your ECR authentication token:
```bash
aws ecr get-login-password --region $ARMONIK_REGION | docker login --username AWS --password-stdin $ARMONIK_DOCKER_REGISTRY
```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `<project_root>`:
```bash
make build-all-infra
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
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

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. An encryption key that will be needed during the deployment:
   ```bash
   make init-grid-state
   ```

2. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-deployment
   ```

3. If successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-runtime
   ```

# Running an example application <a name="running-an-example-application"></a>
In the folder [applications/ArmonikSamples](./applications/ArmonikSamples), you will find the code of the .NET 5.0 Armonik samples.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job and the grid are implemented by a client in folder [applications/ArmonikSamples/Client](./applications/ArmonikSamples/Client).

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

# Clean and destroy Armonik resources <a name="clean-and-destroy-armonik-resources"></a>
In the root forlder `<project_root>`, to destroy all Armonik resources deployed on the local machine, execute the following commands:

1. Delete the launched Kubernetes job, example:
```bash
kubectl delete -f ./generated/single-task-dotnet5.0.yaml
```

2. Destroy all Armonik resources:
```bash
make destroy-dotnet-runtime
```

3. Clean Terraform project:
```bash
make clean-grid-deployment
```

4. Delete the KMS key:
```bash
make delete-grid-state
```

5. Clean binaries and generated files:
```bash
make clean-grid-project
```

6. **If you want remove ALL** local docker images:
```bash
docker rmi -f $(docker images -a -q)
```

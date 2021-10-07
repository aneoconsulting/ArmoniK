# Table of contents
1. [Configure AWS Cli](#configure-aws-cli)
2. [Configure the environment](#configure-the-environment)
3. [Build Armonik artifacts](#build-armonik-artifacts)
4. [Deploy Armonik resources](#deploy-armonik-resources)
5. [Running an example workload](#running-an-example-workload)

# Configure AWS Cli <a name="configure-aws-cli"></a>

You need to provide your AWS secret credentials.
```bash
   aws configure
```

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

5. Define the AWS account ID where the grid will be deployed
    ```bash
      export ARMONIK_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

    ```
6. Define the region where the grid will be deployed
   ```bash
      export ARMONIK_REGION=<Your region>
   ```
   `<Your region>` region can be (the list is not exhaustive)
   - `eu-west-1`
   - `eu-west-2`
   - `eu-west-3`
   - `eu-central-1`
   - `us-east-1`
   - `us-west-2`
   - `ap-northeast-1`
   - `ap-southeast-1`

7. Define an environment variable containing AWS ECR registry.
   ```bash
      export ARMONIK_DOCKER_REGISTRY=$ARMONIK_ACCOUNT_ID.dkr.ecr.$ARMONIK_REGION.amazonaws.com
   ```

8. Define an environment variable to select API Gateway service.
   ```bash
      export ARMONIK_API_GATEWAY_SERVICE=APIGateway
   ```

9. ECR authentication. As you'll be uploading images to ECR, to avoid timeouts, refresh your ECR authentication token:
   ```bash
      aws ecr get-login-password --region $ARMONIK_REGION | docker login --username AWS --password-stdin $ARMONIK_ACCOUNT_ID.dkr.ecr.$ARMONIK_REGION.amazonaws.com
   ```
   
10. Define an environment variable to select API Gateway service.
   ```bash
      export ARMONIK_API_GATEWAY_SERVICE=APIGateway
   ```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s. 

To build and install these in `<project_root>`:
```bash
make dotnet50-path TAG=$ARMONIK_TAG TASKS_TABLE_SERVICE=$ARMONIK_TASKS_TABLE_SERVICE REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY REGION=$ARMONIK_REGION DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY API_GATEWAY_SERVICE=$ARMONIK_API_GATEWAY_SERVICE
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following 
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. Create S3 buckets. The following step creates the S3 buckets and an encryption key that will be needed during the installation:
   ```bash
   make init-grid-state TAG=$ARMONIK_TAG REGION=$ARMONIK_REGION

   ```

2. Run the following to initialize the Terraform environment: 
   ```bash
   make init-grid-deployment TAG=$ARMONIK_TAG REGION=$ARMONIK_REGION
   ```
   
3. If successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-runtime TAG=$ARMONIK_TAG REGION=$ARMONIK_REGION REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
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

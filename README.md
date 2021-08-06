# HTC-Grid-C# Prototype Changes

### New Additional Software Prerequisites

#### On Amazon Linux OS 

* dotnet 5.0+
```bash
      wget https://dot.net/v1/dotnet-install.sh
      bash ./dotnet-install.sh -c Current
      # Add dotnet to your path, e.g.,
      vi ~/.bashrc
      export PATH=/home/ec2-user/.dotnet:$PATH
```
    * RedisClient dotnet add package StackExchange.Redis --version 2.2.50

#### On other OS
To install .NET Core SDK and Runtime in other OS and distributions (Windows, Linux, macOS), please follow the instructions given in this link: [Install .NET on Windows, Linux, and macOS](https://docs.microsoft.com/en-us/dotnet/core/install/)

#### Amazon Lambda Function
```bash
dotnet tool install -g Amazon.Lambda.Tools
dotnet new lambda.image.EmptyFunction --output mock_subtasking --region eu-west-1
```

#### HTC Grid in local
##### On Linux OS
To deploy HTC Grid in local on Linux OS, you can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/).
- To install K3s:
```bash
curl -sfL https://get.k3s.io | sh -
sudo chmod 755 /etc/rancher/k3s/k3s.yaml
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```
- To uninstall K3s
```bash
/usr/local/bin/k3s-uninstall.sh
```

##### On Windows

### Compiling C# libraries

Use Makefile in the root directory to compile all dependencies
```bash
    make http-apis TAG=$TAG ACCOUNT_ID=$HTCGRID_ACCOUNT_ID REGION=$HTCGRID_REGION BUCKET_NAME=$S3_LAMBDA_HTCGRID_BUCKET_NAME

    make build-dotnet5.0
    OR
    make build-dotnet5.0-api
    make build-htc-grid-dotnet5.0-api
    make build-dotnet5.0-simple-client
 ```

 ### New project PATHs
 - Sample C# Client `examples/client/csharp/SimpleClient.cs`
 - HTC-Grid .Net API `source/client/csharp/api-v0.1/HTCGridConnector.cs`
 - OpenAPI for HTTP (generated) `generated/csharp/http_api`


### Priority Queues:

- ``grid_queue_service`` set to SQS or PrioritySQS in config json. If set to SQS then no additional configuration is required.
- ``grid_queue_config`` is a custom config dictionary that is used to configure the corresponding type of the queueing service. At the moment for the priority queues it has only on attribute {'priorities':3}. Note at the moment it is a single quote.
- By default the number of priorities is set to 5. To change that you need to modify the ``sqs.tf`` file where the mapping between a queue name and its priority is maintained.
- Queue's priority is the suffix that is appended to the name of the queue e.g., ``__1``

# HTC-Grid
The high throughput compute grid project (HTC-Grid) is a container based cloud native HPC/Grid environment. The project provides a reference architecture that can be used to build and adapt a modern High throughput compute solution using underlying AWS services, allowing users to submit high volumes of short and long running tasks and scaling environments dynamically.

**Warning**: This project is an Open Source (Apache 2.0 License), not a supported AWS Service offering.

### When should I use HTC-Grid ?
HTC-Grid should be used when the following criteria are meet:
1. A high task throughput is required (from 250 to 10,000+ tasks per second).
2. The tasks are loosely coupled.
3. Variable workloads (tasks with heterogeneous execution times) are expected and the solution needs to dynamically scale with the load.

### When should I not use the HTC-Grid ?
HTC-Grid might not be the best choice if :
1. The required task throughput is below 250 tasks per second: Use [AWS Batch](https://aws.amazon.com/batch/) instead.
2. The tasks are tightly coupled, or use MPI. Consider using either [AWS Parallel Cluster](https://aws.amazon.com/hpc/parallelcluster/) or [AWS Batch Multi-Node workloads](https://docs.aws.amazon.com/batch/latest/userguide/multi-node-parallel-jobs.html) instead
3. The tasks uses third party licensed software.

### How do I use HTC-Grid ?

The following documentation describes HTC-Grid's system architecture, development guides, troubleshooting in further detail.

* [Architecture](docs/architecture.md)
* [HTC-Grid usage guide](docs/guide.md)
* [API reference](docs/reference.md)
* [HTC-Grid project contribution guide](docs/development.md)


## Getting Started

This section steps through the HTC-Grid's AWS infrastructure and software prerequisites. An AWS account is required along with some limited familiarity of AWS services and terraform. The execution of the [Getting Started](#getting-started) section will create AWS resources not included in the free tier and then will incur cost to your AWS Account. The complete execution of this section will cost at least 50$ per day.

### Local Software Prerequisites

The following resources should be installed upon you local machine (Linux and macOS only are supported).

* docker version > 1.19

* kubectl version > 1.19 (usually installed alongside Docker)

* python 3.7

* [virtualenv](https://pypi.org/project/virtualenv/)

* [aws CLI version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

* [terraform v1.0.0](https://releases.hashicorp.com/terraform/1.0.0/) or [terraform v0.14.9](https://releases.hashicorp.com/terraform/0.14.9/) or

* [helm](https://helm.sh/docs/helm/helm_install/) version > 3

* [JQ](https://stedolan.github.io/jq/)



### Installing the HTC-Grid software

Unpack the provided HTC-Grid software ZIP (i.e: `htc-grid-0.1.0.tar.gz`)  or clone the repository into a local directory of your choice; this directory referred to in this documentation as `<project_root>`. Unless stated otherwise, all paths referenced in this documentation are relative to `<project_root>`.

For first time users or windows users, we do recommend the use of Cloud9 as the platform to deploy HTC-Grid. The installation process uses Terraform and also make to build up artifacts and environment. This project provides a CloudFormation Cloud9 Stack that installs all the pre-requisites listed above to deploy and develop HTC-Grid. Just follow the standard process in your account and deploy the **[Cloud9 Cloudformation Stack](/deployment/dev_environment_cloud9/cfn/cloud9-htc-grid.yaml)**. Once the CloudFormation Stack has been created, open either the **Output** section in CloudFormation or go to **Cloud9** in your AWS console and open the newly created Cloud9 environment.

### Configuring Local Environment

#### AWS CLI

Configure the AWS CLI to use your AWS account: see https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

Check connectivity as follows:

```bash
$ aws sts get-caller-identity
{
    "Account": "XXXXXXXXXXXX",
    "UserId": "XXXXXXXXXXXXXXXXXXXXX",
    "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/XXXXXXX"
}
```

#### Python

The current release of HTC requires python3.7, and the documentation assumes the use of *virtualenv*. Set this up as follows:

```bash
$ cd <project_root>/
$ virtualenv --python=$PATH/python3.7 venv
created virtual environment CPython3.7.10.final.0-64 in 1329ms
  creator CPython3Posix(dest=<project_roor>/venv, clear=False, no_vcs_ignore=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/Users/user/Library/Application Support/virtualenv)
    added seed packages: pip==21.0.1, setuptools==54.1.2, wheel==0.36.2
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator

```

Check you have the correct version of python (`3.7.x`), with a path rooted on `<project_root>`, then start the environment:

```
$  source ./venv/bin/activate
(venv) 8c8590cffb8f:htc-grid-0.0.1 $
```

Check the python version as follows:

```bash
$ which python
<project_root>/venv/bin/python
$ python -V
Python 3.7.10
```

For further details on *virtualenv* see https://sourabhbajaj.com/mac-setup/Python/virtualenv.html

### Define variables for deploying the infrastructure
1. To simplify this installation it is suggested that a unique <TAG> name (to be used later) is also used to prefix the different required bucket. TAG needs to follow [S3 naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).
   ```bash
      export TAG=<Your tag>
   ```
2. Define the region where the grid will be deployed
   ```bash
      export HTCGRID_REGION=<Your region>
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

3. Define the AWS account ID where the grid will be deployed
   ```bash
      export HTCGRID_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
   ```
   
4. Define the type of the database service 
   ```bash
      export HTCGRID_TASKS_TABLE_SERVICE=<Your DB service>
   ```
   `<Your DB service>` can be (the list is not exhaustive)
   - `DynamoDB`
   - `MongoDB`

### Create the S3 Buckets

1. The following step creates the S3 buckets  and an encryption key that will be needed during the installation:

  ```bash
  make init-grid-state  TAG=$TAG REGION=$HTCGRID_REGION
  ```
### Create and deploy HTC-Grid images

The HTC-Grid project has external software dependencies that are deployed as container images. Instead of downloading each time from the public DockerHub repository, this step will pull those dependencies and upload into the your [Amazon Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/).

**Important Note** HTC-Grid uses a few open source project with container images stored at [Dockerhub](https://hub.docker.com/). Dockerhub has a [download rate limit policy](https://docs.docker.com/docker-hub/download-rate-limit/). This may impact you when running this step as an anonymous user as you can get errors when running the terraform command below. To overcome those errors, you can re-run the terraform command and wait until the throttling limit is lifted, or optionally you can create an account in [hub.docker.com](https://hub.docker.com/) and then use the credentials of the account using `docker login` locally to avoid anonymous throttling limitations.


1. As you'll be uploading images to ECR, to avoid timeouts, refresh your ECR authentication token:

   ```bash
   make ecr-login
   ```

2. Now run the command

   ```bash
   make init-images  TAG=$TAG REGION=$HTCGRID_REGION
   ```

4. If successful, you can now run *terraform apply* to create the HTC-Grid infrastructure. This can take between 10 and 15 minutes depending on the Internet connection.

    ```bash
    make transfer-images  TAG=$TAG REGION=$HTCGRID_REGION
    ```

NB: This operation fetches images from external repositories and creates a copy into your ECR account, sometimes the fetch to external repositories may have temporary failures due to the state of the external repositories, If the `terraform apply` fails with errors such as the ones below, re-run the command until `terraform apply` successfully completes.

```bash
name unknown: The repository with name 'xxxxxxxxx' does not exist in the registry with id
```

### Build HTC artifacts

HTC artifacts include: .NET Core packages, docker images, configuration files for HTC and k8s. To build and install these:


2. Now build the images for the HTC agent. Return to  `<project_root>`  and run the command:

   ```bash
   make dotnet50-path TAG=$TAG REGION=$HTCGRID_REGION TASKS_TABLE_SERVICE=$HTCGRID_TASKS_TABLE_SERVICE
   ```

   * If `TAG` is omitted then `mainline` will be the chosen has a default value.
   * If `REGION` is omitted then `eu-west-1` will be used.

   A folder name `generated` will be created at  `<project_root>`. This folder should contain the following two files:
    * `grid_config.json` a configuration file for the grid with basic setting
    * `single-task-test.yaml`  the kubernetes configuration for running a single tasks on the grid.



### Configuring the HTC-Grid runtime
The `grid_config.json` is ready to deploy, but you can tune it before deployment.
Some important parameters are:
* **region** : the AWS region where all resources are going to be created.
* **grid_storage_service** : the type of storage used for tasks payloads, configurable between [S3 or Redis]
* **eks_worker** : an array describing the autoscaling  group used by EKS

### Create needed credentials (on-premises)
For the on-premises deployment, some credentials are needed to be defined by the user.

1. Run the following command to create mock credentials needed for the HTC Agents.
   ```bash
   kubectl create secret generic htc-agent-secret-mock --from-literal='AWS_ACCESS_KEY_ID=mock_secret_key' --from-literal='AWS_SECRET_ACCESS_KEY=mock_secret_key'
   ```

2. Run 
   ```bash
   kubectl create secret docker-registry regcred   --docker-server=$HTCGRID_ACCOUNT_ID.dkr.ecr.$HTCGRID_REGION.amazonaws.com   --docker-username=AWS   --docker-password=$(aws ecr get-login-password)
   ```

3. Run
   ```bash
   kubectl create secret generic htc-agent-secret --from-literal='AWS_ACCESS_KEY_ID=<aws_access_key>' --from-literal='AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>'
   ```


### Deploying HTC-Grid

The deployment time is about 30 min.

1. Run
   ```bash
   make init-grid-deployment  TAG=$TAG REGION=$HTCGRID_REGION
   ```
2. if successful you can run terraform apply to create the infrastructure. HTC-Grid deploys a grafana version behind cognito. The admin password is configurable and should be passed at this stage.
   ```bash
   make apply-dotnet-runtime  TAG=$TAG REGION=$HTCGRID_REGION
   ```



### Testing the deployment


1. If `make apply-custom-runtime  TAG=$TAG REGION=$HTCGRID_REGION` is successful then in the terraform folder two files are  created:

    * `kubeconfig_htc_$TAG`: this file give access to the EKS cluster through kubectl (example: kubeconfig_htc_aws_my_project)
    * `Agent_config.json`: this file contains all the parameters, so the agent can run in the infrastructure

2. Testing the Deployment
    1. Get the number of nodes in the cluster using the command below. Note: You should have one or more nodes. If not please the review the configuration files and particularly the variable `eks_worker`
       ```bash
       kubectl get nodes
       ```

    2. Check is system pods are running using the command below. Note: You should have all pods in running state (this might one minute but no more).

       ```bash
       kubectl -n kube-system get po
       ```

    3. Check if logging and monitoring is deployed using the command below. Note: You should have all pods in running state (this might one minute but no more).

       ```bash
       kubectl -n amazon-cloudwatch get po
       ```

    4. Check if metric server is deployed using the command below. Note: You should have all pods in running state (this might one minute but no more).

       ```bash
       kubectl -n custom-metrics get po
       ```

### Running the example workload
In the folder [mock_computation](./examples/workloads/c++/mock_computation), you will find the code of the C++ program mocking computation. This program can sleep for a given duration or emulate CPU/memory consumption based on the input parameters.
We will use a kubernetes Jobs to submit  one execution of 1 second of this C++ program. The communication between the job and the grid are implemented by a client in folder [./examples/client/python](./examples/client/python).

1. Make sure the connection with the grid is established
   ```bash
   kubectl get nodes
   ```
   if an error is returned, please come back to step 2 of the [previous section](#testing-the-deployment).

2. Change directory to `<project_root>`
3. Run the test:
   ```bash
   kubectl apply -f ./generated/single-task-dotnet5.0.yaml
   ```
3. look at the log of the submission:
   ```bash
   kubectl logs job/single-task -f
   ```
   The test should take about 3 second to execute.
   If you see a successful message without exceptions raised, then the test has been successfully executed.


3. clean the job submission instance:
   ```bash
   kubectl delete -f ./generated/single-task-test.yaml
   ```

### Accessing Grafana
The HTC-Grid project captures metrics into influxdb and exposes those metrics through Grafana. To secure Grafana
we use [Amazon Cognito](https://aws.amazon.com/cognito/). You will need to add a user, using your email, and a password
to access the Grafana landing page.

1. To find out the https endpoint where grafana has been deployed type:

    ```
    kubectl -n grafana get ingress | tail -n 1 | awk '{ print "Grafana URL  -> https://"$4 }'
    ```

    It should output something like:

    ```
    Grafana URL  -> https://k8s-grafana-grafanai-XXXXXXXXXXXX-YYYYYYYYYYY.eu-west-2.elb.amazonaws.com
    ```

    Then take the ADDRESS part and point at that on a browser. **Note**:It will generate a warning as we are using self-signed certificates. Just accept the self-signed certificate to get into grafana

2. Log into the URL. Cognito login screen will come up, use it to sign up with your email and a password.
3. On the AWS Console open Cognito and select the `htc_pool` in the `users_pool` section, then select the `users and groups` and confirm user that you just created. This will allow the user to log in with the credentials you provided in the previous step.
4. Go to the grafana URL above, login and use the credentials that you just signed up with and confirmed. This will take you to the grafana dashboard landing page.
5. Finally, in the landing page for grafana, you can use the user `admin` and the password that you provided in the **Deploying HTC-Grid** section. If you did not provide any password the project sets the default `htcadmin`. We encourage everyone to set a password, even if the grafana dashboard is protected through Cognito.


### Un-Installing and destroying HTC grid
The destruction time is about 15 min.
1. From the root of the project.
2. To remove the grid resources run the following command:
   ```bash
   make destroy-custom-runtime TAG=$TAG REGION=$HTCGRID_REGION
   ```
3. To remove the images from the ECR repository, execute
   ```bash
   make destroy-images TAG=$TAG REGION=$HTCGRID_REGION
   ```
4. Finally, this will leave the 3 only resources that you can clean manually, the S3 buckets. You can remove the folders using the following command
   ```bash
   make delete-grid-state TAG=$TAG REGION=$HTCGRID_REGION
   ```

### Build the documentation

1. Go at the root of the git repository
2. run the following command
    ```
    make doc
    ```
    or for deploying the server :
    ```
    make serve
    ```

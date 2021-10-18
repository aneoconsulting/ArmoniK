# Table of contents
1. [Configure the environment](#configure-the-environment) 
2. [Build Armonik artifacts](#build-armonik-artifacts)
3. [Install Kubernetes on local machine](#install-kubernetes-on-local-machine)
4. [Deploy Armonik resources](#deploy-armonik-resources)
5. [Running an example workload](#running-an-example-workload)
6. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

# Configure the environment <a name="configure-the-environment"></a>
Define variables for deploying the infrastructure as follows:
1. To simplify this installation it is suggested that a unique <ARMONIK_TAG> name (to be used later) is also used to prefix the
   different required resources.
   ```bash
      export ARMONIK_TAG=<Your tag>
   ```

2. Define the type of the database service
   ```bash
      export ARMONIK_TASKS_TABLE_SERVICE=MongoDB
   ```
   
3. Define the type of the message queue
   ```bash
      export ARMONIK_QUEUE_SERVICE=RSMQ
   ```

4. Define an environment variable containing the path to the local nuget repository.
   ```bash
      export ARMONIK_NUGET_REPOS=<project directory>/dist/dotnet5.0
   ```

5. Define an environment variable containing the path to the redis certificates.
   ```bash
      export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=<redis certificates directory path>
   ```

6. Define an environment variable containing the docker registry if it exists, otherwise initialize the variable to empty.
   ```bash
      export ARMONIK_DOCKER_REGISTRY=<docker registry>
   ```
   
7. Define an environment variable to select API Gateway service.
   ```bash
      export ARMONIK_API_GATEWAY_SERVICE=NGINX
   ```

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>
Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `<project_root>`:
```bash
make dotnet50-path TASKS_TABLE_SERVICE=$ARMONIK_TASKS_TABLE_SERVICE QUEUE_SERVICE=$ARMONIK_QUEUE_SERVICE REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY API_GATEWAY_SERVICE=$ARMONIK_API_GATEWAY_SERVICE
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.

## Debug mode
To build in `debug` mode, you execute this command:
```bash
make dotnet50-path BUILD_TYPE=Debug TASKS_TABLE_SERVICE=$ARMONIK_TASKS_TABLE_SERVICE QUEUE_SERVICE=$ARMONIK_QUEUE_SERVICE REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY API_GATEWAY_SERVICE=$ARMONIK_API_GATEWAY_SERVICE
```

For more information see [here](./docs/debug.md)

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

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>
1. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-local-deployment
   ```

2. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
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
make destroy-dotnet-local-runtime REDIS_CERTIFICATES_DIRECTORY=$ARMONIK_REDIS_CERTIFICATES_DIRECTORY DOCKER_REGISTRY=$ARMONIK_DOCKER_REGISTRY
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
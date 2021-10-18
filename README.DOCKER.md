# Table of contents
1. [Build Docker image](#build-docker-image)
2. [Start Docker image](#start-docker-image)
3. [Build Armonik artifacts](#build-armonik-artifacts)
4. [Deploy Armonik resources](#deploy-armonik-resources)
5. [Running an example workload](#running-an-example-workload)
6. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

# Build Docker image <a name="build-docker-image"></a>

```bash
docker build -t armonik:dev .
```

# Start Docker image <a name="start-docker-image"></a>

```bash
docker run -it --rm --privileged armonik:dev bash
```

If you don't provide the `bash` command, the container will run with no shell and you would need to `docker exec` within the container.
The container has currently no volume, so any modification (in particular the build) will be lost when the container is terminated.

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

4. **If you want** remove all local docker images:
```bash
docker rmi -f $(docker images -a -q)
```

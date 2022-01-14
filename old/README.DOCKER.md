# Table of contents
1. [Build Docker image](#build-docker-image)
2. [Start Docker image](#start-docker-image)
3. [Deploy Armonik resources](#deploy-armonik-resources)
4. [Running an example workload](#running-an-example-workload)
5. [Clean and destroy Armonik resources](#clean-and-destroy-armonik-resources)

# Build Docker image <a name="build-docker-image"></a>

There is two modes for the image: the user image, and the dev image.
The user image goal is to pull pod images during the deployment, while the dev image is meant to build locally (inside the container) the pod images, before deployement.

## Build arguments

There are a few arguments to the build:
- `MODE`: which mode to use: `user` or `dev`. default = `user`
- `DOCKER_REGISTRY`: tell which registry to use when pulling. If empty the images must be built locally. default = `dockerhubaneo`
- `BUILD_ID`: suffix to the tag of docker images for pods. default = `XXXX`
- `TAG`: tag of of docker images for pods. default = `armonik-dev-$BUILD_ID`
- `BUILD_TYPE`: Either `Release` or `Debug`. default = `Release`
- `APP`: Application to build. default = `ArmonikSamples`

## User image

```bash
docker build -t armonik-components:user --build-arg MODE=user --build-arg BUILD_ID=XXXX .
```

Where XXXX is the build id corresponding to the current version of the repo


## Dev image

```bash
docker build -t armonik-components:dev --build-arg MODE=dev --build-arg DOCKER_REGISTRY= .
```

# Start Docker image <a name="start-docker-image"></a>

```bash
docker run -it --rm --privileged armonik-components:user bash
```

If you don't provide the `bash` command, the container will run with no shell and you would need to `docker exec` within the container.
The container has currently no volume, so any modification (in particular the build) will be lost when the container is terminated.

# Build Armonik artifacts <a name="build-armonik-artifacts"></a>

Building artifacts is required (and possible) only in the dev mode.

Armonik artifacts include: .NET Core packages, docker images, configuration files for Armonik and k8s.

To build and install these in `/armonik`:
```bash
make all ARMONIK_APPLICATION_NAME=<Name of your sample>
```

A folder named `generated` will be created at `<project_root>`. This folder should contain the following
two files:
 * `local_dotnet5.0_runtime_grid_config.json` a configuration file for the grid with basic setting.
 * `local-single-task-dotnet5.0.yaml` the kubernetes configuration for running a single tasks on the grid.


Those files are already created for the user mode during image build.

# Deploy Armonik resources <a name="deploy-armonik-resources"></a>

The deployement procedure is the same for both modes (user and dev).

1. Run the following to initialize the Terraform environment:
   ```bash
   make init-grid-local-deployment
   ```

2. if successful you can run terraform apply to create the infrastructure:
   ```bash
   make apply-dotnet-local-runtime
   ```

# Running an example workload <a name="running-an-example-workload"></a>
In the folder [applications/ArmonikSamples](./applications/ArmonikSamples), you will find the code of the .NET 5.0
Armonik samples.

We will use a kubernetes Jobs to submit one execution of this .NET program. The communication between the job and the
grid are implemented by a client in folder [applications/ArmonikSamples/Client](./applications/ArmonikSamples/Client).

1. Export the location of the client config file. The config is passed this way for ArmonikSamples and HtcMock. This may be different for your application.
   ```bash
   export CLIENT_CONFIG_FILE=generated/Client_config.json
   ```

2. Run your application
   ```
   dotnet generated/$ARMONIK_APPLICATION_NAME/Client/Client.dll
   ```

# Clean and destroy Armonik resources <a name="clean-and-destroy-armonik-resources"></a>
In the root forlder `<project_root>`, to destroy all Armonik resources deployed on the local machine, execute the following commands:

1. Destroy all Armonik resources:
```bash
make destroy-dotnet-local-runtime
```

2. Clean Terraform project, binaries and generated files:
```bash
make clean-grid-local-project
```

3. **If you want** remove all local docker images:
```bash
docker rmi -f $(docker image ls --format="{{json .}}" | jq "select( (.Tag==\"$ARMONIK_TAG\") ) .ID" | tr -d \")
```

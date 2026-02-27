### Prepare the infrastructure

1. Add a `cppdynamic` partition to your infrastructure.

    ```diff
    +cppdynamic = {
    +  # number of replicas for each deployment of compute plane
    +  replicas = 0
    +  # ArmoniK polling agent
    +  polling_agent = {...
    +  }
    +  # ArmoniK workers
    +  worker = [
    +    {
    +      image = "dockerhubaneo/armonik-sdk-cpp-dynamicworker"
    +      tag = "0.4.2" 
    +      limits = {...}
    +      requests = {...}
    +    }
    +  ]
    +  hpa = {...
    +  }
    +}

2. Redeploy ArmoniK to include the new partition.

### Building and runnig

You have two options to build the example, either you install the ArmoniK API and SDK packages for your distribution and then compile
the client executable and the worker shared library directly in your system. Or, you might use docker containers. 

#### Building in your system

1. Look and install for the right package for your distribution for:

    - [ArmoniK.Api](https://github.com/aneoconsulting/ArmoniK.Api/releases/latest)
    - [ArmoniK.Extensions.Cpp](https://github.com/aneoconsulting/ArmoniK.Extensions.Cpp/releases/latest)

2. Compile the worker shared library and copy it to ArmoniK's shared data folder

```bash
    cd worker && mkdir build
    cmake -B build -S .
    cmake --build ./build
```

This should produce shared object `libArmoniK.Samples.Cpp.Hello.SDK.Worker.so` that should be copied
to ArmoniK's shared data folder, for a localhost deployment, the default folder is located at
`/path/to/ArmoniK/repository/infrastructure/quick-deploy/localhost/data/`. 

3. Compile the client

```bash
    cd client && mkdir build
    cmake -B build -S .
    cmake --build ./build
```

This should produce an executable `ArmoniK.Samples.Cpp.Hello.SDK.Client`, that requires the following
configuration variables to be set: 

- `GrpcClient__Endpoint`: Your cluster entry point
- `PartitionId`: The partition name for the dynamic Cpp worker

You can either define them as environment variables before running the client executable or you can create
a `appsettings.json` file in the same directory where the executable is located with the following information


```json

{
"GrpcClient":{
    "Endpoint": "http://xxx.xxx.xxx:5001 " 
    },
    "PartitionId": "cppdynamic"
}

```

#### Using a Docker Container

The provided `Makefile` includes two recipes:
- **build_client**: This recipe compiles the client executable.
- **build_worker**: This recipe compiles the worker library, which depends on the dynamic worker provided by the SDK.

To run the client in a Docker container, use the following command:
```bash
docker run --rm -e GrpcClient__Endpoint=http://xxx.xxx.xxx:5001 -e PartitionId=cppdynamic armonik-samples-cpp-hello-client:0.0.0-sdk
```

You should see output similar to this:
```bash
2026-02-12T14:35:41.603825170z	[Info]	Starting Hello World ArmoniK Client...
2026-02-12T14:35:41.645418366z	[Info]	Session ID: 3fbeebca-083d-416a-b0db-f866d92d13f5
2026-02-12T14:35:41.707404226z	[Info]	Task Submitted: e4cdeead-5fb2-4892-a643-82cd17393e90
2026-02-12T14:35:42.224763338z	[Info]	HANDLE RESPONSE : Received result of size 13 for taskId e4cdeead-5fb2-4892-a643-82cd17393e90
Content : Hello, World!
Raw : 72 101 108 108 111 44 32 87 111 114 108 100 33 

2026-02-12T14:35:42.725067083z	[Info]	Task Processing Complete.

```

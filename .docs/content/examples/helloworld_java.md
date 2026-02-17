### Prepare the infrastructure

1. Add a helloworld partition to [parameters.tfvar](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/localhost/parameters.tfvars).

    ```diff
    +helloworld = {
    +  # number of replicas for each deployment of compute plane
    +  replicas = 0
    +  # ArmoniK polling agent
    +  socket_type = "tcp"
    +  polling_agent = {...
    +  }
    +  # ArmoniK workers
    +  worker = [
    +    {
    +      image = "hello-world-worker"
    +      tag = "latest" 
    +      limits = {...}
    +      requests = {...}
    +    }
    +  ]
    +  hpa = {...
    +  }
    +}


2. Redeploy ArmoniK to include the new partition.

3. Make sure your system has the following dependencies installed:

    - Java 17 or higher
    - Maven 3.9+

### Worker

Start by building your JAR and worker image:

```bash

cd ArmoniK.Samples/java/workers/hello-world-worker
./mvnw clean package

```

This command:
1. Compiles the Java code
2. Creates a shaded JAR with all dependencies
3. Builds a Docker image named `hello-world-worker:latest` using Jib


### Client

Compile the client:

```bash

cd ArmoniK.Samples/java/client
./mvnw clean package

```

### Submit a task

```bash

./mvnw compile exec:java -Dexec.mainClass="fr.aneo.armonik.client.samples.HelloWorld"

```

The console will show something like this:

```bash

15:38:20.592 [fr.aneo.armonik.client.samples.HelloWorld.main()] WARN  f.a.a.client.GrpcChannelBuilder - SECURITY WARNING: Insecure plaintext connection enabled for endpoint http://localhost:5001. This disables all encryption and should only be used for development or internal networks.
15:38:20.937 [ArmoniK-Client-0] WARN  f.a.a.client.GrpcChannelBuilder - SECURITY WARNING: Insecure plaintext connection enabled for endpoint http://localhost:5001. This disables all encryption and should only be used for development or internal networks.
15:38:20.942 [fr.aneo.armonik.client.samples.HelloWorld.main()] WARN  f.a.a.client.GrpcChannelBuilder - SECURITY WARNING: Insecure plaintext connection enabled for endpoint http://localhost:5001. This disables all encryption and should only be used for development or internal networks.
Blob completed - id: 6b704266-03d7-4ffd-8dcb-60beaee241cd, data: Hello John. Welcome to Armonik Java Worker !!
15:38:21.058 [ArmoniK-Client-0] INFO  f.a.a.c.BlobCompletionCoordinator - All blob completion operations finished. SessionId: d53f638d-c33f-4da3-9418-ea55f6b7a093
15:38:21.058 [fr.aneo.armonik.client.samples.HelloWorld.main()] INFO  f.a.a.client.ManagedChannelPool - Shutting down channel pool (size: 3, unbounded: false)
15:38:23.069 [ForkJoinPool.commonPool-worker-2] WARN  f.a.a.client.ManagedChannelPool - Channel did not terminate within 2000ms, forcing shutdown
15:38:23.073 [fr.aneo.armonik.client.samples.HelloWorld.main()] INFO  f.a.a.client.ManagedChannelPool - Channel pool shutdown complete

```
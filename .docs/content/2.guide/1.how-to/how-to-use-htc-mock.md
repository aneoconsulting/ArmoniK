# How to use HTC Mock?

HTC Mock is a test tool for ArmoniK. It is used to generate tasks that will be runned by ArmoniK. It provides a lot of options to personalize the tasks.

HTC Mock is used in CI to test ArmoniK automatically but it can also be used in development to generate realistic tasks.

::alert{type="info"}
To populate the database, you can also use some scripts to populate database. See [Populate database?](../populate-database.md)
::

## Use it

::alert{type="warning"}
HTC Mock is a development or test tool. It is not intended to be used in production.
::

To use HTC Mock, you need to swap out the ArmoniK worker in `/infrastructure/quick-deploy/localhost/armonik/parameters.tfvars` with the HTC Mock worker.

```diff [parameters.tfvars]
    worker = [
      {
        name              = "worker"
-       image             = "dockerhubaneo/armonik_worker_dll"
+       image             = "dockerhubaneo/armonik_core_htcmock_test_worker"
        tag               = "0.12.1"
    ]
```

Then, you can update the tag version. You can verify the [latest of Core on GitHub](https://github.com/aneoconsulting/ArmoniK.Core/release/latest) in order to use it.

:warning: `dockerhubaneo/armonik_control` `dockerhubaneo/armonik_pollingagent` and `dockerhubaneo/armonik_core_htcmock_test_worker` must have the **exact** same tag version. It is necessary so they can talk to each other using the same API.

Then, you can deploy ArmoniK as usual.

```bash [shell]
make deploy-armonik
```

Then you can start the HTC mock client container.

```bash [shell]
docker run --rm \
            -e HtcMock__NTasks=100 \
            -e HtcMock__TotalCalculationTime=00:00:00.100 \
            -e HtcMock__DataSize=1 \
            -e HtcMock__MemorySize=1 \
            -e HtcMock__EnableFastCompute=true \
            -e HtcMock__SubTasksLevels=1 \
            -e HtcMock__Partition=htcmock \
            -e GrpcClient__Endpoint=http://<ip>:5001 \
             dockerhubaneo/armonik_core_htcmock_test_client:0.12.1
```

Don't forget to replace `<ip>` with the IP of your machine or the IP of the machine where ArmoniK is deployed.

## Options

They must be prefixed by `HtcMock__` and can be passed as environment variables or as command line arguments.

| Name                 | Description                                                                                                                                  | Default value  |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| NTasks               | Number of computing tasks (there are some supplementary aggregation tasks)                                                                   | `100`          |
| TotalCalculationTime | Total computation time for the computing tasks                                                                                               | `100ms`        |
| DataSize             | Size of the task outputs                                                                                                                     | `1`            |
| MemorySize           | Size of the memory used by the task during its execution                                                                                     | `1`            |
| SubTasksLevels       | Number of sub tasks levels.                                                                                                                  | `4`            |
| EnableFastCompute    | Whether the computing tasks will take the time parameter into consideration. Always used to generate the graph of task dependencies.         | `true`         |
| EnableUseLowMem      | Whether the computing tasks will take the memory usage parameter into consideration. Always used to generate the graph of task dependencies. | `true`         |
| EnableSmallOutput    | Whether the computing tasks will take the output size parameter into consideration. Always used to generate the graph of task dependencies.  | `true`         |
| TaskRpcException     | Raise RpcException when task id ends by this string, ignored if empty string                                                                 | `string.Empty` |
| TaskError            | Finish task with Output when task id ends by this string, ignored if empty string                                                            | `string.Empty` |
| Partition            | Partition in which to submit the tasks                                                                                                       | `string.Empty` |

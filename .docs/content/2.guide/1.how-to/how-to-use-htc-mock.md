# How to use HTC Mock?

HTC Mock is a test tool for ArmoniK. It is used to generate tasks that will be run by ArmoniK. It provides a lot of options to personalize the tasks.

HTC Mock is used in CI to test ArmoniK automatically but it can also be used in development to generate realistic tasks.

Please make sure your version of Core is the same as HTC Mock's. If you use different versions, the test will fail. Please refer to [the Default images page](https://aneoconsulting.github.io/ArmoniK/guide/default-images) for more information on how to correctly set up.

::alert{type="info"}
To populate the database, you can also use scripts.  See [Populate database](../populate-database.md)
::

## Use it

::alert{type="warning"}
HTC Mock is a development or test tool. It is not intended to be used in production.
::

You now have the choice between a multi-stages deployment or an All-in-one deployment. You can use HTC Mock with both but the setup will differ depending on your choice.

### Multi-stages deployment

To use HTC Mock, you need to swap out the ArmoniK worker in `/infrastructure/quick-deploy/localhost/armonik/parameters.tfvars` with the HTC Mock Worker.

```diff [parameters.tfvars]
    worker = [
      {
        name              = "worker"
-       image             = "dockerhubaneo/armonik_worker_dll"
+       image             = "dockerhubaneo/armonik_core_htcmock_test_worker"
        tag               = "0.12.1"
    ]
```

You can update the tag version. Please verify the [latest of Core on GitHub](https://github.com/aneoconsulting/ArmoniK.Core/release/latest) in order to use it.

:warning: `dockerhubaneo/armonik_control` `dockerhubaneo/armonik_pollingagent` and `dockerhubaneo/armonik_core_htcmock_test_worker` must have the **exact** same tag version. It is necessary so they can talk to each other using the same API.

Then, you can deploy ArmoniK as explained in the [multi-stages deployment page](https://aneoconsulting.github.io/ArmoniK/installation/linux/deployment)

You are now ready to start the HTC mock client container.

```bash [shell]
docker run --rm \
            -e HtcMock__NTasks=100 \
            -e HtcMock__TotalCalculationTime=00:00:00.100 \
            -e HtcMock__DataSize=1 \
            -e HtcMock__MemorySize=1 \
            -e HtcMock__EnableFastCompute=true \
            -e HtcMock__SubTasksLevels=1 \
            -e HtcMock__Partition="" \
            -e GrpcClient__Endpoint=http://<ip>:5001 \
             dockerhubaneo/armonik_core_htcmock_test_client:0.12.1
```

Remember to replace `<ip>` with the IP of your machine or the IP of the machine where ArmoniK is deployed.

### All-in-one deployment

For an all-in-one deployment, you will need to specify on which partition you want to deploy HTCMock.

For more information about the All-in-one deployment, please refer to the [All-in-one deployment page](https://aneoconsulting.github.io/ArmoniK/installation/linux/all-in-one-deployment)

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

Remember to replace `<ip>` with the IP of your machine or the IP of the machine where ArmoniK is deployed.

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

# How to use HTC Mock?

HTC Mock is a test tool for ArmoniK. It is used to generate tasks that will be run by ArmoniK. It provides a lot of options to personalize the tasks.

HTC Mock is used in CI to test ArmoniK automatically but it can also be used in development to generate realistic tasks.

Please make sure your version of Core is the same as HTC Mock's. If you use different versions, the test will fail. Please refer to [the Default images page](../../user-guide/default-images.md) for more information on how to correctly set up.


## Use it


```{warning}


HTC Mock is a development or test tool. It is not intended to be used in production.

```

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
             dockerhubaneo/armonik_core_htcmock_test_client:<armonik_version_core>
```

Remember to replace `<ip>` with the IP of your machine or the IP of the machine where ArmoniK is deployed.

Remember to replace  `<armonik_version_core>` with the [current core version](https://github.com/aneoconsulting/ArmoniK/blob/main/versions.tfvars.json)

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

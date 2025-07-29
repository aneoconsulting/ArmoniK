# ArmoniK benchmarking

This folder contains the tfvars for the benchmarks on AWS.

The results are stored in the bucket `http://armonik-bench-storage.s3-website.eu-west-3.amazonaws.com` with the commit hash, and the parameters used to run the benchmark.
The is the pattern of the file: `http://armonik-bench-storage.s3-website.eu-west-3.amazonaws.com/PREFIX/REF/RUNID_DATE/benchclient_benchmark_TRIGGER_TYPE_results.json` where:
- `PREFIX`: is `manual`, `release`, or empty
- `REF`: is the name of the branch or the tag used for the benchmark
- `RUNID`: is the github action run ID
- `DATE`: is the date at which the benchmark was ran (`YYYY-MM-DD-hh-mm-ss-UTC`)
- `TRIGGER`: is the event that triggered the benchmark (`push`, `release`, or `workflow_dispatch`)
- `TYPE`: is the type of deployment (`localhost` or `aws`)

Here is an example of result:

```json
{
  "context": {
    "parameters": "https://github.com/aneoconsulting/ArmoniK/blob/930b7f641d8e1f60bbff31385996cf68337dabbe/infrastructure/quick-deploy/localhost/parameters.tfvars",
    "versions": "https://github.com/aneoconsulting/ArmoniK/blob/930b7f641d8e1f60bbff31385996cf68337dabbe/versions.tfvars.json",
    "commit": "930b7f641d8e1f60bbff31385996cf68337dabbe",
    "reference": "refs/heads/fl/bench-improv",
    "run-id": "16074981540",
    "event": "push",
    "type": "localhost",
    "date": "2025-07-04-13-39-46-UTC",
    "ntasks": "3000",
    "polling_limit": "300",
    "session_id": "8c75d15c-df89-4322-9a79-468feb823d81",
    "session_name": "bench"
  },
  "metrics": {
    "throughput": {
      "name": "Throughput",
      "unit": "Task per second",
      "value": 49.02761889197581
    },
    "tasks_count": {
      "name": "Total number of tasks",
      "unit": "Task",
      "value": 3000
    }
  }
}
```

On every releases, benchmarks are ran both on AWS and locally on the runner.
On every commit on main, benchmarks are ran only locally on the runner.
At any time, one can run the benchmarks on any branch from github actions manual workflow dispatch.
For manual run, it is possible to run either localhost or AWS.

To reproduce a benchmark, you need to checkout ArmoniK on the commit that was used for the benchmark (as seen in the result JSON), and use the benchmark tfvars.

For instance on AWS:

```sh
git checkout $COMMIT_SHA
cd infrastructure/quick-deploy/aws
make deploy PARAMETERS_FILE=../../../benchmarking/aws.tfvars
```

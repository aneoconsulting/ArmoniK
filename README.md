# ArmoniK benchmarking

### Are you lost ?

If you are reading this, you are either involved in <em>ArmoniK</em> benchmarking project, interested in how we defined our infrastructure for benchmarking or you have unpurposely gotten astray from the main trunk !

# Definition of ArmoniK benchmarking infrastructure on AWS

## First one

Related to AK benchmarking project, this branch exists to keep track of the first benchmark configuration used to define AK benchmarking infrastructure on AWS.

This first benchmark configuration basically takes ArmoniK as of v2.20.1 and executes a Bench client session through a Kubernetes job for replication concerns. See the [YAML manifest for this Bench client session](https://github.com/aneoconsulting/ArmoniK/blob/ts/bench-1/tools/benchmarks/bench-1-job.yaml).

# ArmoniK

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/aneoconsulting/ArmoniK?color=fe5001&label=latest%20version&sort=semver)
 ![GitHub](https://img.shields.io/github/license/aneoconsulting/ArmoniK)

<em>ArmoniK</em> is a high throughput compute grid project using Kubernetes. The project provides a reference
architecture that can be used to build and adapt a modern high throughput compute solution on-premise or using Cloud
services, allowing users to submit high volumes of short and long-running tasks and scaling environments dynamically.

## Documentation

Please, read [documentation](https://aneoconsulting.github.io/ArmoniK/) for more information about ArmoniK.

- 👉 [ArmoniK Architecture](https://aneoconsulting.github.io/ArmoniK/armonik)
- 👉 [ArmoniK Versions](https://aneoconsulting.github.io/ArmoniK/armonik#versions)
- 👉 [ArmoniK Installation](https://aneoconsulting.github.io/ArmoniK/installation)
- 👉 [ArmoniK Configuration](https://aneoconsulting.github.io/ArmoniK/guide/how-to/how-to-configure-authentication)
- 👉 [ArmoniK Performance](https://aneoconsulting.github.io/ArmoniK/benchmarking/test-plan)


## Bug

You are welcome to raise issues on GitHub. Please, read our [community guidelines](https://aneoconsulting.github.io/ArmoniK.Community/) before doing so.

You can also send us a direct email at [armonik-support@aneo.fr](mailto:armonik-support@aneo.fr).

## Acknowledge

This project was funded by AWS and started with their [HTCGrid project](https://awslabs.github.io/aws-htc-grid/).

## License

[Apache License, Version 2.0](https://github.com/aneoconsulting/ArmoniK/blob/main/LICENSE)

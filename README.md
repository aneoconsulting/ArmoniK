# ArmoniK

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/aneoconsulting/ArmoniK?color=fe5001&label=latest%20version&sort=semver)
 ![GitHub](https://img.shields.io/github/license/aneoconsulting/ArmoniK)

<em>ArmoniK</em> is a high throughput compute grid project using Kubernetes. The project provides a reference
architecture that can be used to build and adapt a modern high throughput compute solution on-premise or using Cloud
services, allowing users to submit high volumes of short and long-running tasks and scaling environments dynamically.

## ArmoniK versions

<!-- TODO: Must move the documentation -->

The current version of ArmoniK uses the tags listed in [armonik-versions.txt](https://github.com/aneoconsulting/ArmoniK/blob/main/armonik-versions.txt) where:

* `core` is the ArmoniK Core tag used for container images of Control plane, Polling agent and Metrics exporter.
* `worker` is the tag used for the container image of the workers
* `admin-gui` is the tag used for the container images of ArmoniK AdminGUI (admin-api and admin-app)
* `samples` is the tag for ArmoniK Samples

## Documentation

Please, read [documentation](https://aneoconsulting.github.io/ArmoniK/) for more information about ArmoniK.

- 👉 [ArmoniK Architecture](https://aneoconsulting.github.io/ArmoniK/armonik)
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

# Table of contents

- [ArmoniK](#armonik)
    - [When should I use ArmoniK](#when-should-i-use-armonik)
    - [When should I not use ArmoniK](#when-should-i-not-use-armonik)
- [ArmoniK versions](#armonik-versions)
- [ArmoniK deployment](#armonik-deployment)
- [How to run ArmoniK.Samples](#how-to-run-armoniksamples)
- [Acknowledge](#acknowledge)
- [Bugs/Support](#bugssupport)

# ArmoniK

<em>ArmoniK</em> is a high throughput compute grid project using Kubernetes. The project provides a reference
architecture that can be used to build and adapt a modern high throughput compute solution on-premise or using Cloud
services, allowing users to submit high volumes of short and long-running tasks and scaling environments dynamically.

**Warning**: This project is an Open Source (Apache 2.0 License).

## When should I use ArmoniK

ArmoniK should be used when the following criteria are meet:

1. A high task throughput is required (from 250 to 10,000+ tasks per second).
2. The tasks are loosely coupled.
3. Variable workloads (tasks with heterogeneous execution times) are expected and the solution needs to dynamically
   scale with the load.

## When should I not use ArmoniK

ArmoniK might not be the best choice if :

1. The required task throughput is below 250 tasks per second.
2. The tasks are tightly coupled, or use MPI.
3. The tasks use third party licensed software.

# ArmoniK versions

The current version of ArmoniK uses the tags listed in [armonik-versions.txt](./armonik-versions.txt) where:

* `core` is the ArmoniK Core tag used for container images of Control plane, Polling agent and Metrics exporter.
* `worker` is the tag used for the container image of the workers
* `admin-gui` is the tag used for the container images of ArmoniK AdminGUI (admin-api and admin-app)
* `samples` is the tag for ArmoniK Samples

# ArmoniK deployment

All instructions to build, deploy and test ArmoniK software on Linux are described
in [ArmoniK deployment](./infrastructure/README.md)

# How to run ArmoniK.Samples

Please Clone the repository Armonik.Samples into the [Root_Armonik_folder]/Source/

```bash
git clone https://github.com/aneoconsulting/ArmoniK.Samples.git
```

Instructions to run ArmoniK.Samples are described
in [Run Samples](https://github.com/aneoconsulting/ArmoniK.Samples/blob/main/README.md)

# Acknowledge

This project was funded by AWS and started with their [HTCGrid project](https://awslabs.github.io/aws-htc-grid/).

# Bugs/Support

Please direct enquiries about ArmoniK to the public mailing
list [armonik-support@aneo.fr](mailto:armonik-support@aneo.fr).

See also [Issues](https://github.com/aneoconsulting/ArmoniK/issues) of ArmoniK project.

To report a bug or request a feature, please use and follow the instructions in one of
the [issue templates](https://github.com/aneoconsulting/ArmoniK/issues/new/choose). Don't forget to include the version
of ArmoniK you are using.

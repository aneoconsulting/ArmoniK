# ArmoniK

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/aneoconsulting/ArmoniK?color=fe5001&label=latest%20version&sort=semver)
 ![GitHub](https://img.shields.io/github/license/aneoconsulting/ArmoniK)

ArmoniK is an open-source platform and programming model for writing and executing scalable, fault-tolerant parallel and distributed workloads. ArmoniK brings the simplicity and flexibility of serverless computing to complex and compute-intensive applications across cloud or on-premises infrastructures.

With ArmoniK, developers can run distributed workloads made up of millions of tasks using many programming languages (C++, C#, Java, Python, Rust, etc.), without worrying about the low-level orchestration, data shuffling, or failure recovery mechanisms.

## Table of Contents

## What is ArmoniK

### Overview

ArmoniK is designed to execute workloads described as dynamic task graphs in a fault-tolerant, cloud-agnostic, and language-agnostic environment. It scales effortlessly to thousands of cores and adapts to failures like task failures, node crashes and network disrupt, making it ideal for high-performance, business-critical workloads.

Example use cases include:
* Scientific and financial simulations
* Machine learning pipelines
* Video and signal processing
* Iterative algorithms

One of ArmoniK key feature is subtasking: tasks can dynamically generate new tasks at runtime, enabling DAG reshaping and adaptive workflows.

### Architecture

ArmoniK follows a modular architecture made of stateless services and pluggable components. The architecture can be tuned to meet specific requirements like: performance, cost-efficiency, company-specific rules, etc.

The following figure shows an abstract view of ArmoniK's architecture.

[Insert figure]

* Storage: Consists of a database (e.g., MongoDB) and object store (e.g., S3, MinIO) to persists execution state.
* Message Queue: Drives event-based execution (e.g., RabbitMQ, Redis, SQS).
* Submitter: Gateway for job submissions and monitoring.
* Scheduling Agents: Control task lifecycle, data flow, and error handling.
* Workers: Run user-defined code for executing tasks. 

### Deployment

ArmoniK official deployments include:
* Cloud: AWS, GCP and any cloud-based Kubernetes environment.
* On-premises: Bare metal or private Kubernetes clusters
* Local: Lightweight setup for development

### What is this repository?

This repository serves as the entry point for the ArmoniK ecosystem. It contains:
* Useful scripts.
* Terraform templates and deployment samples for:
    * Local setup
    * AWS (EKS, S3, etc.)
    * GCP (GKE, Pub/Sub, etc.)
    * On-prem Kubernetes

If you're looking for code or components, check the other repositories below:
* Core: Heart of the system (schedulers, models, orchestration). Licensed under GPLv3.
* API: gRPC definitions and multi-language bindings.
* CLI: Command-line interface for job submission, inspection, and resource management.
* Infra: Terraform modules and Helm charts for infrastructure provisioning.
* Samples: End-to-end usage examples in C++, Python, C#, Java, and Rust.

## Documentation

Please, read [documentation](https://armonik.readthedocs.io/en/latest/) for more information about ArmoniK.

- 👉 [ArmoniK Architecture](https://armonik.readthedocs.io/en/latest/content/armonik/index.html)
- 👉 [ArmoniK Versions](https://armonik.readthedocs.io/en/latest/content/armonik/index.html#versions)
- 👉 [ArmoniK Getting Started](https://armonik.readthedocs.io/en/latest/content/armonik/getting-started.html)
- 👉 [ArmoniK Configuration](https://armonik.readthedocs.io/en/latest/content/user-guide/how-to-configure-authentication.html)
- 👉 [ArmoniK Performance](https://armonik.readthedocs.io/en/latest/content/benchmarking/test-plan.html)


## Bug

You are welcome to raise issues on GitHub. Please, read our [community guidelines](https://aneoconsulting.github.io/ArmoniK.Community/) before doing so.

You can also send us a direct email at [armonik@aneo.fr](mailto:armonik@aneo.fr).

## Acknowledge

This project was funded by AWS and started with their [HTCGrid project](https://awslabs.github.io/aws-htc-grid/).

## License

This repository and most ArmoniK components are licensed under the [Apache License, Version 2.0](https://github.com/aneoconsulting/ArmoniK/blob/main/LICENSE). The exception is the ArmoniK.Core component, which is licensed under the GNU GPL v3.
* Apache 2.0: Allows commercial use, modification, and distribution.
* GPL v3: Requires that modifications to the core also be shared under the same license.

Please review the individual repo licenses before integration.

## Contributing

We welcome contributions of all kinds:
* Feature implementations
* Documentation improvements
* Bug reports and fixes
* New examples or language bindings

To get started:
* Fork the relevant repository
* Create a feature branch
* Open a Pull Request with a clear description

For major changes, please start a discussion or open an issue first.
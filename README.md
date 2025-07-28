# 👋 Welcome to ArmoniK

## 🚀 What is ArmoniK?

**ArmoniK** is an **open-source, high-throughput task orchestrator** designed to run large-scale, parallel workloads efficiently across Kubernetes-based infrastructure.

It enables the execution of **millions of distributed, containerized tasks** with automatic scaling, resilience, and observability — suitable for scientific, industrial, or analytic workloads.

---

## Documentation

Please, read [documentation](https://armonik.readthedocs.io/en/latest/) for more information about ArmoniK.

- 👉 [ArmoniK Architecture](https://armonik.readthedocs.io/en/latest/content/armonik/index.html)
- 👉 [ArmoniK Versions](https://armonik.readthedocs.io/en/latest/content/armonik/index.html#versions)
- 👉 [ArmoniK Getting Started](https://armonik.readthedocs.io/en/latest/content/armonik/getting-started.html)
- 👉 [ArmoniK Configuration](https://armonik.readthedocs.io/en/latest/content/user-guide/how-to-configure-authentication.html)
- 👉 [ArmoniK Performance](https://armonik.readthedocs.io/en/latest/content/benchmarking/test-plan.html)


Thank you — here's the updated **English-only Markdown** with **no mention of clients**, keeping it clean, neutral, and professional. I’ve also trimmed or adapted all statements that previously relied on external case studies or client-specific metrics.

---

## 🛠️ Key Features

* **Task-based parallelism**: Break down your workflows into fine-grained compute tasks.
* **Scalability**: Execute thousands of tasks per second with elastic scaling.
* **Container isolation**: Each task runs in a dedicated container for reproducibility and isolation.
* **Kubernetes-native**: Works seamlessly with K8s (e.g., K3s, EKS, GKE, AKS).
* **Open-source**: Licensed under Apache 2.0 for full transparency and extensibility.
* **Built-in observability**: Metrics, logs, and tracing supported out of the box.

---

## 🔧 Supported Languages & Runtime Model

ArmoniK is usegRPC through its containerized architecture. Supported environments include:

* **C# (.NET Core)** — official SDK available
* **Java** — standard integration supported
* **Python / C++ / others** — via custom worker containers or wrappers

You package your worker code in Docker containers, and ArmoniK takes care of orchestrating its execution in a scalable and resilient way.

---

## ☁️ Infrastructure & Deployment

ArmoniK can run on:

| Environment  | Description                                 |
| ------------ | ------------------------------------------- |
| Local        | Single-node K3s cluster for development     |
| On-Premises  | Full Kubernetes support                     |
| Public Cloud | AWS, Azure, GCP, or any K8s-managed cluster |
| Hybrid       | Combine cloud and on-prem infrastructure    |

Deployment can be automated with tools like **Helm**, **Terraform**, and **CI/CD pipelines**, making ArmoniK suitable for both experimentation and production.

---

## 💼 Use Cases

ArmoniK is suited for any workload that can benefit from **high concurrency** and **task distribution**, including:

* Scientific computation and simulations
* AI/ML model training and evaluation
* Batch analytics pipelines
* Real-time distributed processing
* Risk calculation or combinatorial workloads
* Scalable algorithmic processing (e.g., bioinformatics, Monte Carlo, rendering)

---

## 🎯 Why Use ArmoniK?

* ✅ **High throughput**: Supports intensive workloads with minimal latency.
* ✅ **Resilience**: Tasks are isolated and restartable.
* ✅ **Cost-efficiency**: Dynamically scales up or down with demand.
* ✅ **Customizable**: Create your own workers, integrate with any stack.
* ✅ **Portable**: No vendor lock-in; runs anywhere Kubernetes runs.

---

## 📋 Overview Table

| Aspect               | Detail                                                    |
| -------------------- | --------------------------------------------------------- |
| **Core Role**        | Distributed task orchestrator over Kubernetes             |
| **Execution Model**  | Stateless containerized workers, triggered by task queues |
| **Language Support** | C#, Java, Python, C++, and more via containers            |
| **Deployment**       | K3s, AKS, EKS, GKE, on-prem, or hybrid setups             |
| **Scaling**          | Automatic based on task load and cluster capacity         |
| **Observability**    | Integrates with Prometheus, Grafana, OpenTelemetry, etc.  |
| **License**          | [Apache 2.0](https://github.com/aneoconsulting/ArmoniK/blob/main/LICENSE) |

---

## Bug

You are welcome to raise issues on GitHub. Please, read our [community guidelines](https://aneoconsulting.github.io/ArmoniK.Community/) before doing so.

You can also send us a direct email at [armonik@aneo.fr](mailto:armonik@aneo.fr).

## Acknowledge

This project was funded by AWS and started with their [HTCGrid project](https://awslabs.github.io/aws-htc-grid/).

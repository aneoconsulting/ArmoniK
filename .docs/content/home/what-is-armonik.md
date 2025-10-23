# What is ArmoniK ?

ArmoniK is a hybrid framework designed to simplify the development of distributed applications, particularly in high-performance computing (HPC) and High Throughput environments. It aims to provide a user-friendly interface for scientists and engineers, allowing them to leverage distributed computing resources without requiring deep expertise in parallel programming.

## Why ArmoniK ?

In the computing landscape, supercomputing capabilities have significantly evolved from past decades. For example, the JUGENE supercomputer (2007) achieved 222 TFlops, while by 2025, Nvidia's GB200 chip is expected to reach 160 TFlops. This implies a shift in how we've approached computational power, where what once required significant resources is now manageable with more common systems. In simplified terms: older supercomputers function as single nodes today, making past high-performance
tasks more accessible and commonplace. This fact also has an impact in the current understanding of workload demands: HPC typically involves a few large, complex jobs, whereas HTC involves many small, independent tasks. However, contemporary workloads blend these approaches, consisting of numerous small computations interlinked through complex dependencies.

This shift necessitates a hybrid model, showcasing that many small computations now require extensive data management, task dependency resolution, and a mix of HPC/HTC strategies. Our vision emphasizes ArmoniK as a bridge between these two paradigms, enabling efficient execution of many-task computing in diverse applications.

## Key Features of ArmoniK

### Goals
- **Simplifies Development**: It allows for easier creation of distributed applications.
- **User-Friendly Interface**: Designed to be accessible to scientists and engineers without deep technical skills.
- **Performance Optimization**: Facilitates achieving reasonable performance levels for applications.

### Architecture
- **Computational Kernels**: Users can define their computational tasks.
- **Data Management**: Manages data reading, writing, and inter-process communication.
- **Task-Based Programming**: Breaks down complex operations into smaller tasks, allowing for more manageable development and execution. This includes task distribution, load balancing, and dependency resolution through a distributed scheduler.

### Built-in Features
- **Open Source**: Available for users to modify and contribute to via GitHub.
- **Fault Tolerance**: Ensures continuation of operations even with node failures.
- **Advanced Data Management**: Supports overlapping computations and communications, checkpointing, and prefetching.
- **Observability**: Provides extensive monitoring tools including GUIs and APIs for tracking application performance.
- **Portability and Malleability**: Supports multiple programming languages (C#, C++, Python, etc.) and dynamic resource allocation during execution.
- **Production Ready**: Focused on stability and security, making it suitable for critical systems.

## Importance and Use Cases

ArmoniK addresses the growing complexity in heterogeneous computing systems by allowing easier access to performance at scale, enabling scalability without the need to re-architect codes. This enables users to focus on their activities rather than the intricacies of parallel programming. It is especially useful in scenarios where resource sharing and efficient resource utilization are critical. Hence, ArmoniK stands out as a solution aimed at bridging the gap between complex HPC requirements and user accessibility, making it a significant tool for modern scientific research and engineering.

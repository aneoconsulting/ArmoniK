##  ArmoniK Deployment, Application Principles and Rules

### Deployment

- **Use the same version for all components of ArmoniK Core:**
  - Agent
  - Metrics exporter
  - Control plane

- **Utilize Helm charts** to deploy ArmoniK on Kubernetes.

- **Leverage ArmoniK dependencies** to manage services as much as possible, particularly:
  - **AWS:** Use S3 for object storage and SQS for the queue.
  - **GCP:** Use GCS for object storage and PubSub for the queue.
  - **On-premises deployment:** Use MinIO for object storage and RabbitMQ (version ≥ 4.0) for the queue. Note that we have less experience in this area, but these are our current recommendations.
  - **MongoDB Atlas** for MongoDB, if feasible.

- **Avoid using Seq for log storage;** while it is a good solution for developers on personal machines, it is not suitable for multi-user environments.

- **Properly size Prometheus and the metrics exporter,** as they are fundamental components of Horizontal Pod Autoscaling (HPA) and monitoring. Configuration of data retention and persistence is essential. We recommend having two Prometheus instances:
  - One dedicated to HPA: a smaller instance with data retention measured in hours.
  - A second dedicated to monitoring: a larger instance with data retention measured in days (e.g., one week).

- **Ensure compliance with your security rules and implement the following measures:**
  - Regularly scan the Docker images of ArmoniK (Control Plane, Polling Agent, Worker Ext, Metrics Exporter, Pod Deletion Cost, Admin GUI, Meta Controller), as well as other public components (Prometheus, Nginx, Grafana, MongoDB, Mongosh, Fluent-bit), and the Docker images of private applications from the pricing service (e.g., DLLs running in the worker).
  - Update Docker images frequently to address Common Vulnerabilities and Exposures (CVEs).
  - Enable data-at-rest encryption as soon as possible (e.g., S3, ElastiCache, Amazon MQ, EFS).
  - Enable in-transit encryption for communications as soon as possible (e.g., ElastiCache, S3).
  - Prefer the use of custom client encryption keys.
  - Implement login/password authentication as soon as possible and secure them via a vault.
  - Use custom certificates signed by the client Certificate Authority (CA) as soon as possible and secure them in a vault or certificate manager.
  - Grant roles with least privilege permissions as soon as possible.
  - Use least privilege resource policies as soon as possible.
  - Implement an authentication and authorization system on the GUI.
  - Use mTLS certificates to connect to ArmoniK.
  - Place ArmoniK workers in a private Virtual Private Cloud (VPC) with controlled access to/from the outside.
  - Limit the opening of ports for managed services (e.g., ElastiCache, Amazon MQ).

### Application Principles
  - Jobs should not access standard file systems or relational database servers during execution. Filesystem mounts are not permitted. If external storage access is necessary, use a dedicated Object Storage plug-in.
  - To ensure that all nodes can be utilized for all applications, no application can leave any footprints on the computing nodes. Therefore, no application should assume direct access to the compute nodes.
  - No application data should be stored on local disks. Temporary results should be provided to ArmoniK as a result of the task.
  - The application and tasks submitted should not have any scheduling functions. Multithreading is allowed, but tasks should not assume scheduling capabilities.
  - No task-to-task communication is permitted. Tasks should not assume that other tasks are running concurrently and should not attempt to communicate with one another.

### Application Rules
  - As a best practice, individual tasks should run for between a few seconds and 180 seconds to minimize work loss in case of task failure and to optimize the distributed environment.
  - Applications should be designed to support the loss of any worker at any time, ideally using stateless workers.
  - No task should actively wait for another to complete. Instead, utilize ArmoniK's dependency mechanism.
  - Avoid creating never-ending tasks to artificially reserve resources. Define custom autoscaling metrics to pre-allocate compute resources.
  - Ensure that tasks can be terminated and rescheduled without negatively impacting the workload (at both session and overall application operating time).
  - The grace period of your application must not exceed the grace period of the physical instances (2 minutes for AWS spot instances, between 15 seconds and 2 minutes on GCP spot instances). In other situations, it should not exceed 3 minutes.
  - Never introduce a potential Single Point of Failure (SPOF) or other centralized sharing or database services that cannot scale with application growth.
  - Long tasks (one hour or more) must be split into smaller tasks (ten or twenty minutes as a best practice target). As a last resort, implement a recovery mechanism to utilize saved data from the G2S mutualized cache service.
  - Whenever possible, avoid accessing the compute node's local disk, as up to 40 tasks (cores) could access it simultaneously.

# Changelog

## [main](https://github.com/aneoconsulting/armonik/tree/main) (2022-06-22)

## [v2.8.0](https://github.com/aneoconsulting/armonik/tree/v2.8.0) (2022-06-22)

Added
-

* Add admin GUI
* Add and implement GetResultStatus in Armonik.Api
* Implement TryGetResult to match Api
* Unified API delivery with User, Admin and monitoring API
* Set fs.inotify.max_user_instances to 8192 in worker nodes on AWS
* Expose the parameters of the cluster autscaler's Helm chart in Terraform sources

Changed
-

* Rootless docker images for ArmoniK components
* Replace ports of ArmoniK components' containers from 80 to 1080
* Refactoring tasks creation in ArmoniK Core
* Update database scheme: replace sessions options from string to object, add creation date in the session object
* Refactoring RequestProcessor
  * Improve error management in tryGetResult when tasks in error
* Upgrade and replace tags "latest" of the infrastructure's docker images
* Upgrade the version of hashicorp/aws to 4.18.0
* Update Terraform sources of AWS ElastiCache to publish logs in AWS CloudWatch 
* Update Helm chart of ArmoniK's KEDA HPA

Fixed
-

* Fix GetTaskStatus exception when task ID does not exist
* Reduce crashes of polling-agent
* Remove from the queue messages of tasks that no longer exist in the database MongoDB
* fix the exception MongoDBWaitQueueFullException : the wait queue for acquiring a connection is full
* Fix errors occurring with large number of subtasks
* Reconfigure inputs of fluent-bit to eliminate the error on SQlite DB

## [v2.7.3](https://github.com/aneoconsulting/armonik/tree/v2.7.3) (2022-06-09)

Fixed
-

* Fix strong name for Armonik.API

## [v2.7.2](https://github.com/aneoconsulting/armonik/tree/v2.7.2) (2022-06-02)

Removed
-

* Remove Armonik.Proto project and merge into Armonik.Extension.API

Added
-

* Add HealthCheck for Worker Service
* Add Strong name for Client Assemblies
* Ingress option to avoid grpc timeout exception
* Add list session for Administration API
* Add infrastructure for Admin GUI

Changed
-

* Fix Issue with Properties object in datasynapse client sdk
* Fix issue with Gateway timeout Error 504
* Supply Strong name in Client Extension.CSharp for .Net 4.8 Libraries
* Update Proto API in Extensions.CSharp
* Fix Cancel Session
* Fix issue with requested Adress Localhost:80
* Fix issue with large task request

## [v2.7.1](https://github.com/aneoconsulting/armonik/tree/v2.7.1) (2022-05-17)

Removed
-

* Ignore IdleReplicaCount option in KEDA SacledObject Helm chart
* Delete idle_replica_count parameter in HPA of compute plane
* Remove GetStatus for TryGetResult

Added
-

* Add annotations in the Kubernetes deployments of ArmoniK components. The user who deploys ArmoniK can fill the
  annotations via the parameters.tfvars
* Add tags in Terraform sources for AWS resources (VPC, ECR, EKS, AWS ElastiCache, Amazon MQ)
* Add gRPC channel factory to support mTLS in core test clients
* Add tests in fully integrated tests in core
* Update Samples and Extensions.API End to end test to be compliant with .net 4.8

Changed
-

* Upgrade KEDA Helm chart to version 2.7.2
* Upgrade KEDA container images to version 2.7.1
* update Core package dependencies to reduce vulnerabilities
* Expose ClientOptions in Callback OnSessionEnter
* Change default working directory to Application will be executed
* Change to .net 6.0 in WorkerAPI Service

## [v2.7.0](https://github.com/aneoconsulting/armonik/tree/v2.7.0) (2022-05-11)

Removed
-

* Prometheus Adapter is removed and replaced by KEDA
* Remove dispatcher from Polling Agent
* Remove task creating metrics from queued task metrics for HPA

Added
-

* KEDA is used for Horizontal Pod Autoscaling (HPA)
* Use KEDA Prometheus scaler for HPA
* Health check is added in Control plane
* Add stability + larges tests in Polling agent and control plane
* Add configuration management of task priority for ActivMQ
* Add new timeout configuration when no more space left
* Add configuration in ActivMQ to upgrade pending messages in queue to 1OOM messages
* Add Dotnet Framework 4.8 in High level Client API
* Add Retry communication from Client when communication is lost during waiting or getResult
*

Fixed
-

* Fix the problem of multiple APIservice of custom.metrics.k8s.io or external.metrics.k8s.io on the same Kubernetes
  cluster.
* Fix tasks Retry in Polling agent
* Fix HealthCheck in compute plane
* Fix and validated cancel session API
* Fix Issue to fix AssemblyLoadContext in Release

Changed
-

* Improve RequestProcessor
* Change heuristic of task submission (Parent task must finished before to start any subtask)
* The retry will generate new taskId in polling agent manage retry of task internaly
* Add start time, submission time, end time in database to monitor task activities
* Improve performance for LogFunction
* Improve performance by removing dispatcher
* Improve index in MongoDB for access performances
* Improve TryGetResult + Fix when error comes from compute plane
* Manage retry when disrupted communications happen between client and server (Default retry 5 WAITING 200ms)
* Increase VM Size for ActivMQ to manage heavy load
* Change storage type from EFS to EBS

## [v2.6.0](https://github.com/aneoconsulting/armonik/tree/v2.6.0) (2022-05-06)

Added
-

* Add Ingress with no SSL, TLS and mTLS functionalities (Default: no SSL)

## [v2.5.2](https://github.com/aneoconsulting/armonik/tree/v2.5.2) (2022-03-28)

Added
-

* Add multiarch images for ArmoniK Core (Control plane, Polling agent, and Metrics exporter)
* Add health checks for Polling agent
* Add Ssl options in API to connect with https protocol
* Add new constructor for GridServer Properties with default Configuration argument
* Add Retry on getResult when Http connections could fail during the result retrieval

Fixed
-

* Fix bugs with deserialization from MongoDB in polling agent and large payloads
* Fix bugs with TryGetResults

## [v2.5.1](https://github.com/aneoconsulting/armonik/tree/v2.5.1) (2022-03-16)

Added
-

* New feature to call static method in GridServer service
* Add default serialization on native array (double[], float[], long[] int[] and so on)

Fixed
-

* Fix messages reinserted in the queue instead of being deleted
* Fix the crashes due to MongoDB
* Fix result storage after task processing
* Fix issue with Properties in GridServer API (One constructor with optional connexion string)
* Fix issue with byte[] in ProtoSerializer
* Fix issue with SessionService in GridServer

## [v2.5.0](https://github.com/aneoconsulting/armonik/tree/v2.5.0) (2022-03-08)

Removed
-

* Remove communication between workers and control-plane

Added
-

* Add metrics exporter of custom metrics of ArmoniK to Prometheus
* Add Prometheus adapter to expose custom metrics of ArmoniK in Kubernetes API service
* Display the custom metrics of ArmoniK in Grafana
* Add Horizontal Pod Autoscaler (HPA) for ArmoniK compute-plane based on the custom metrics
* Add a new low-level API
* Add complementary tags for AWS resources
* Add revision number for application package version

Changed
-

* Improve EKS parameters: full private access to EKS
* Improve logs displaying in Seq

## [v2.4.0](https://github.com/aneoconsulting/armonik/tree/v2.4.0) (2022-02-24)

Removed
-

* Support for external Redis and Htc Mock v1
* Old deployments of storage and ArmoniK

Added
-

* Add liveness, readiness and startup probes for seq
* Add source codes of ArmoniK deployment on local machine in quick-deploy/
* Add source codes of ArmoniK deployment on AWS in quick-deploy/
* Add a script bash to deploy ArmoniK in all-in-one commands
* In addition to Seq, add AWS CloudWatch to monitor application logs of ArmoniK
* The user can configure the *toleration* block of pods via `node_selector` parameter
* Add resource codes for quick deployments on *localhost* and *AWS*
* New Version of nuget package for worker API agent 0.4.0
* New Version of nuget package for ArmoniK core 0.4.1

Changed
-

* Use environment variables instead of configmaps to configure applications in ArmoniK images
* Terraform is used to generate self-signed certificates for ActiveMQ, MongoDB and Redis
* Terraform is used to generate users and passwords for ActiveMQ, MongoDB and Redis
* Certificates and credentials are stored as kubernetes secrets
* ArmoniK expects those secrets as input
* Fluent-bit is used to tail logs and send them to Seq/CloudWatch instead of sending them directly from logger
* Two different implementations of Fluent-bit (the user can choose one of them):
    * As a sidecar in ArmoniK control plane and compute plane
    * As a DaemonSet in each Kubernetes node

## [v2.3.0](https://github.com/aneoconsulting/armonik/tree/v2.3.0) (2022-02-01)

Added
-

* Support for Redis as object storage
* Support for amqp and amqp+ssl protocols
* Add Authentication for MongoDB and encryption in transit (TLS)
* Setup TLS for AMQP, Redis and MongoDB on prem storages
* AWS Virtual Private Cloud (VPC)
* AWS Elastic Kubernetes Service (EKS version 1.21)
* AWS Elastic Container Registry (ECR)
* S3 as shared filesystem for worker containers
* AWS Elasticache (Redis engine version 6.x)
* Amazon MQ (ActiveMQ version 5.16.3)
* Activate CloudWatch logs for :
    * EKS
    * VPC
    * Amazon MQ
* Encryption at rest:
    * VPC flow log in cloudwatch log group
    * EKS cloudwatch log group
    * EKS secrets
    * EBS of EKS nodes
    * ECR
    * S3
    * Elasticache (in transit too)
    * Amazon MQ
* New End-to-End tests mechanism for Symphony API
* New SessionService to manage in multi thread several actives sessions
* New script to deploy ArmoniK on localhost with one script
* New Version of nuget package for worker API agent 0.2.1
* New Version of nuget package for ArmoniK core 0.4.0

Changed
-

* Automate configurations of Kubernetes Kubeadm and K3s onpremise cluster (simulation of onpremise cluster on AWS)

Fixed
-

* Fix issue with multiple Creation of Service (Issue #64)
* Issue with Multi Sessions opened
* Priority check to subtasking. Transfer priority from client to server
* Fix GridServer Service.Submit Signature to return the taskId
* Fix GridServer Service.Execute Signature to return Tuple with TaskId and result object

## [v2.2.0](https://github.com/aneoconsulting/armonik/tree/v2.2.0) (2022-01-17)

Added
-

* GitHub action to deploy ArmoniK infra on GitHub worker and test full integration

changed
-

* New ArmoniK infrastructure:
    * Onpremise for both single node (local machine or VM) and cluster of nodes
    * Split source codes of storage and ArmoniK's components deployments
    * Create an external shared storage, of type host-path on local machine or NFS on a cluster, from which compute
      workers upload their .dll
    * Source codes for dev/test onpremise Kubernetes cluster
* Update ArmoniK.Samples
* Create repositories for control plance, compute plane, Protos and Development kit

Removed
-

* Persistent volumes (PV) and persistent volume claims (PVC) are not used anymore

Fixed
-

* Session stop recrating at each OnInvoke (SendTask) call

## [v2.1.0](https://github.com/aneoconsulting/armonik/tree/v2.1.0) (2022-01-06)

Added
-

* Support for AMQP

## [v2.0.0](https://github.com/aneoconsulting/armonik/tree/v2.0.0) (2021-12-17)

Added
-

* New implementation for the compute plane
* New implementation for the control plane
* New docker images for control plane and compute plane
* Images are prebuilt
* Use Seq to ingest and show logs
* First stage to load dynamically Dll Application
* Dependency and subtasking management and corresponding api
* Priority management and corresponding low level api
* Component management through configuration files or environment variables

Changed
-

* New implementation of Symphony API
* Infrastructure to match the new control plane
* Replace statefulsets by deployments
* Use config maps to configure applications in pods

Removed
-

* NGINX is not needed anymore
* C# deprecated code
* Python deprecated lambdas (previous control plane and agent)

## [v0.9.6](https://github.com/aneoconsulting/armonik/tree/v0.9.6) (2021-12-03)

Changed
-

* Deploy NGINX without using manifest file
* Create separate configuration files for the client/server
* Improve Armonik logs
* Uniformize Armonik API (Client side with ArmonikClient class and hide internal data structures in IServiceContainer)
* Reuse 1.1.1 version of Htc.Mock and add project that implement the interfaces between AmonikClient and Htc.Mock
  interfaces
* Use a Kubernetes secret to connect to Redis (agent/lambda, submit tasks lambda and client)

Added
-

* List of useful scripts ([tools/](./tools)) as displaying logs of compute lambda in agent pods
* Activate dynamodb stream logs and mongodb oplog
* Scripts to process dynamodb stream logs and mongodb oplog so that we can retrieve when tasks change status
* Enrich ArmonikSamples examples
* Create a secret based on SSL/TLS certificates for Redis in Kubernetes

## [v0.9.4](https://github.com/aneoconsulting/armonik/tree/v0.9.4) (2021-11-04)

Fixed
-

* Integration with Htc.Mock
* Debug mode
* Execution of ArmonikSample in AWS

Changed
-

* Create more useful make target to compile only the relevant parts of the project
* Update management of environment variables
* Simplification of folder structure for applications
* Use file and environment variables to track versions of Armonik projects and dependencies
* Compile application client/server on the host instead of inside the build of the images to simplify and accelerate
  compilation

Added
-

* Automatic tag of resources deployed in AWS
* Implement other type of computations in ArmonikSamples
* Ready to used docker image with Armonik installed

## [v0.9.2.RC](https://github.com/aneoconsulting/armonik/tree/v0.9.2.RC) (2021-10-21)

Fixed
-

* Debug mode using BUILD_TYPE=Debug when compiling
* Fix issues with environment variables

## [v0.9.RC](https://github.com/aneoconsulting/armonik/tree/v0.9.RC) (2021-10-19)

Fixed
-

* Deployment in WSL

Changed
-

* Folder structures for applications

Added
-

* Logs and Logger
* Armonik SDK
* Armonik Samples for new SDK
* MongoDB deployment in Kubernetes for Armonik task state DB
* Redis MQ for task message queue

Removed
-

* Dependecies to AWS boto3 in local deployment
* DynamoDB for local deployment
* SQS for local deployment

## [v0.1.8](https://github.com/aneoconsulting/armonik/tree/v0.1.8) (2021-10-14)

Fixed
-

* Remove all proxies from pods

## [v0.1.6](https://github.com/aneoconsulting/armonik/tree/v0.1.6) (2021-10-08)

Fixed
-

* Remove proxy environment variables in pod of client
* Fix and parse the responses of lambda

Changed
-

* Display in realtime information about the executed sample

## [v0.1.4](https://github.com/aneoconsulting/armonik/tree/v0.1.4) (2021-09-29)

Added
-

* Set environment variables of proxy in pods (NO_PROXY, HTTP_PROXY, HTTPS_PROXY, no_proxy, http_proxy, https_proxy)

## [v0.1.2](https://github.com/aneoconsulting/armonik/tree/v0.1.2) (2021-09-22)

Fixed
-

* Fix cancel task lambda and Python example

Changed
-

* Get external IP address on local machine
* Get URL endpoint of Kubernetes services on local machine

## [v0.1.0](https://github.com/aneoconsulting/armonik/tree/v0.1.0) (2021-09-17)

Changed
-

* Deploy LocalStack on local machine
* Replace AWS managed services on local machine
    * DynamoDB on LocalStack
    * SQS on LocalStack
    * AWS ElastiCache replaced by Redis
    * AWS Lambda replaced by Lambda RIE
    * AWS EKS replaced by K3s on Linux and Desktop-docker on Windows
* Code sources for connectors to Armonik resources
* Automate the compilation and the deployment using Makefile

Added
-

* C# code sources for Client and workloads

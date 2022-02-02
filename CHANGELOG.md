# Changelog

## [latest](https://github.com/aneoconsulting/armonik/tree/main) (2022-01-31)

Added
-

* Support for Redis as object storage
* Support for amqp and amqp+ssl protocols
* Add Authentication for MongoDB and encryption in transit (TLS)
* Setup TLS for AMQP, Redis and MongoDB on prem storages

changed
-

* Automate configurations of Kubernetes Kubeadm and K3s onpremise cluster (simulation of onpremise cluster on AWS)

Added
-

* AWS Virtual Private Cloud (VPC)
* AWS Elastic Kubernetes Service (EKS version 1.21)
* AWS Elastic Container Registry (ECR)
* Activate logs for EKS and VPC in CloudWatch
* S3 as shared filesystem for worker containers
* AWS Elasticache (Redis engine version 6.x)
* Encryption at rest:
    * VPC flow log in cloudwatch log group
    * EKS cloudwatch log group
    * EKS secrets
    * EBS of EKS nodes
    * ECR
    * S3
    * Elasticache (in transit too)

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

# Changelog

## [v0.9.4](https://github.com/aneoconsulting/armonik/tree/v0.9.4) (2021-11-04)
Added
-
* Automatic tag of resources deployed in AWS
* Implement other type of computations in ArmonikSamples
* Ready to used docker image with Armonik installed

Changed
-
* Create more useful make target to compile only the relevant parts of the project
* Update management of environment variables
* Simplification of folder structure for applications
* Use file and environment variables to track versions of Armonik projects and dependencies
* Compile application client/server on the host instead of inside the build of the images to simplify and accelerate compilation

Fixed
-
* Integration with Htc.Mock
* Debug mode
* Execution of ArmonikSample in AWS

## [v0.9.2.RC](https://github.com/aneoconsulting/armonik/tree/v0.9.2.RC) (2021-10-21)
Fixed
-
* Debug mode using BUILD_TYPE=Debug when compiling
* Fix issues with environment variables

## [v0.9.RC](https://github.com/aneoconsulting/armonik/tree/v0.9.RC) (2021-10-19)
Added
-
* Logs and Logger
* Armonik SDK
* Armonik Samples for new SDK
* MongoDB deployment in Kubernetes for Armonik task state DB
* Redis MQ for task message queue

Changed
-
* Folder structures for applications

Fixed
-
* Deployment in WSL

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
Changed
- 
* Display in realtime information about the executed sample

Fixed
-
* Remove proxy environment variables in pod of client
* Fix and parse the responses of lambda

## [v0.1.4](https://github.com/aneoconsulting/armonik/tree/v0.1.4) (2021-09-29)
Added
-
* Set environment variables of proxy in pods (NO_PROXY, HTTP_PROXY, HTTPS_PROXY, no_proxy, http_proxy, https_proxy)

## [v0.1.2](https://github.com/aneoconsulting/armonik/tree/v0.1.2) (2021-09-22)
Changed
- 
* Get external IP address on local machine
* Get URL endpoint of Kubernetes services on local machine

Fixed
-
* Fix cancel task lambda  and Python example

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

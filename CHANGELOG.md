# Changelog

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

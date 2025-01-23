# ArmoniK benchmarking on AWS
This folder contains a Terraform parameters file describing the infrastructure that has been chosen as *ArmoniK reference infrastructure on AWS* that is used for regular benchmarks at each ArmoniK release. This file might evolve alongside ArmoniK. 

Thus for reproducibility concerns, this folder also contains subfolders that save dumps of the exact infrastructure configuration used for each version of ArmoniK benchmarked as well as the versions of ArmoniK's components.

The subfolders are actually named as following, given a version *X.X.X* and a commit SHA *123abc* : **X-X-X_123abc**

### How to reproduce an ArmoniK infrastructure for benchmarking ?

1. Choose an ArmoniK version and save the associated subfolder name.

2. Make sure you are at the root of the ArmoniK folder.

3. Go to AWS quick-deploy : `cd infrastructure/quick-deploy/aws`

4. Deploy ArmoniK with the appropriate Terraform parameters files located in the subfolder you selected : `make deploy PARAMETERS_FILE=../../../../benchmarking/aws/{ARMONIK_VERSION}_{COMMIT_SHA}/parameters.tfvars VERSIONS_FILE=../../../../benchmarking/aws/{ARMONIK_VERSION}_{COMMIT_SHA}/versions.tfvars.json`
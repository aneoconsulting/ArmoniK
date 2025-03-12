# ArmoniK CDF Client

This guide explains how to deploy a CDF client job to a Kubernetes cluster running the ArmoniK services. The client job connects to an ArmoniK endpoint and processes tasks on a specified partition. The results are stored in a volume that can be accessed after the job completes.

## Overview

The CDF client job runs a containerized Python application that connects to an ArmoniK endpoint and processes tasks on a specified partition. The results are stored in a volume that can be accessed after the job completes.

## Prerequisites

- Access to a Kubernetes cluster with the ArmoniK services deployed
- kubectl command-line tool installed and configured
- AWS CLI installed and configured (for ECR access)
- Docker installed (for building and pushing images)

## Usage Guide

### 1. Build and Push the Client Image to ECR

Before deploying the job, you need to build your client application and push it to ECR:

```bash
# Set your ECR registry URL
export ECR_REGISTRY=<your-ecr-registry-url>

# Log in to ECR
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build your client Docker image
docker build -t cdf-client:latest /path/to/your/client/code

# Tag the image for ECR
docker tag cdf-client:latest $ECR_REGISTRY/cdf-client:latest

# Push the image to ECR
docker push $ECR_REGISTRY/cdf-client:latest
```

### 2. Configure and Deploy the Job

Deploy the infrastructure on aws using the following command:

```bash
cd tools/cdf/infrastructure/aws
make deploy PREFIX=<your-prefix>
```

Update the client-job.yaml file with your specific configuration:

```bash
# Deploy the job to Kubernetes
kubectl apply -f client-job.yaml
```

### 3. Monitor the Job

Track the status of your job:

```bash
# Check job status
kubectl get jobs -n armonik armonik-client-job

# Check the pod status
kubectl get pods -n armonik -l job-name=armonik-client-job

# View logs from the client
kubectl logs -n armonik -l job-name=armonik-client-job
```

### 4. Extract Result Files

After your job completes, you can extract the files from the pod:

```bash
# Get the pod name
export POD_NAME=$(kubectl get pods -n armonik -l job-name=armonik-client-job -o jsonpath='{.items[0].metadata.name}')

# Create a local directory for results
mkdir -p ./cdf-results
```

```bash	
 POD_NAME=armonik-client-job-<X>\nkubectl exec -n armonik $POD_NAME -- find /app/data -name "*.csv" | while read filepath; do\n  filename=$(basename "$filepath")\n  kubectl cp armonik/$POD_NAME:"$filepath" ~/cdf-results/csv/"$filename"\ndone
```

```bash	

 POD_NAME=armonik-client-job-<X>\nkubectl exec -n armonik $POD_NAME -- find /app/data -name "*.html" | while read filepath; do\n  filename=$(basename "$filepath")\n  kubectl cp armonik/$POD_NAME:"$filepath" ~/cdf-results/html/"$filename"\ndone
```	

```bash	

 POD_NAME=armonik-client-job-<X>\nkubectl exec -n armonik $POD_NAME -- find /app/data -name "*.png" | while read filepath; do\n  filename=$(basename "$filepath")\n  kubectl cp armonik/$POD_NAME:"$filepath" ~/cdf-results/png/"$filename"\ndone
```
### 5. Clean Up

After extracting your files, you can delete the job:

```bash
kubectl delete job -n armonik armonik-client-job
```

## Configuration Options

The client job supports the following environment variables:

- `ARMONIK_ENDPOINT`: The gRPC endpoint for the ArmoniK control plane service
- `ARMONIK_PARTITION`: The partition name to submit tasks to (default: "cdf")
- `RESULTS_DIR`: Directory where results will be stored (default: "/app/data/results")

## Troubleshooting

If your job fails, check the logs for error messages:

```bash
kubectl logs -n armonik -l job-name=armonik-client-job
```

For persistent issues, you may need to check the container's environment or configuration.

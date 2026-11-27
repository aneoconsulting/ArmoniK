# AWS quick deploy with the ArmoniK Helm charts

One Terraform stack: the AWS resources through the ArmoniK.Infra modules, then ArmoniK through its charts (module
`armonik-charts`).

## Deployed by default

| | |
|---|---|
| Cluster | EKS 1.35, Cilium in ENI mode (no VPC CNI, no kube-proxy, Hubble), system node group 2x t3a.medium, Karpenter pools `core` (on-demand) and `workers` (spot first) |
| Network | VPC with one NAT gateway, S3 gateway endpoint, NLB on `ingress_allowed_cidrs` (AWS Load Balancer Controller) |
| Storage | Aurora PostgreSQL 18, provisioned or Serverless v2 (optional RDS Proxy), S3 or S3 Express One Zone (`object_storage`), SQS |
| ArmoniK | chart of Infra #450, Core 0.41.5, GetEvents on a control plane Deployment of its own, Prometheus, Grafana, Seq |
| Partitions | `htcmock` (scale to zero) and those of the stack |
| Bench monitoring | Grafana folder Bench (run, compute, PostgreSQL, tasks, SQS and S3, network) over CloudWatch, postgres_exporter and SQL; `bench_monitoring = false` removes it |

The dashboards are generated: edit `charts/bench-monitoring/dashboards/gen.py`, then
`python3 charts/bench-monitoring/dashboards/gen.py` and apply.

## Setup

```sh
cp registry-credentials.auto.tfvars.example registry-credentials.auto.tfvars   # then fill it in
cp stacks/aws.tfbackend.example stacks/armonik69/aws.tfbackend                   # then fill it in
```

## armonik69

```sh
terraform init -reconfigure -backend-config=stacks/armonik69/aws.tfbackend
terraform apply -var-file=stacks/armonik69/aws.tfvars
```

## Destroy

```sh
terraform destroy -var-file=stacks/armonik69/aws.tfvars
```

The repositories the pull-through cache created (`<prefix>/docker-hub/...`) and the SQS queues Core created
(`<prefix>*`) are not in the state:

```sh
aws ecr describe-repositories --query "repositories[?starts_with(repositoryName, 'armonik69/')].repositoryName" --output text
aws sqs list-queues --queue-name-prefix armonik69
```

## HtcMock

3000 tasks of about 200 ms of real compute (10 min in total) on 3 levels of subtasks, on the `htcmock` partition, which
scales from zero. From the cluster, the client skips the internet and pulls its image through the ECR cache:

```sh
kubectl -n armonik run htcmock --rm -it --restart=Never \
  --image=$(terraform output -json registries | jq -r .dockerHub)/dockerhubaneo/armonik_core_htcmock_test_client:0.41.5 \
  --env=GrpcClient__Endpoint=http://armonik-ingress:5001 \
  --env=HtcMock__Partition=htcmock \
  --env=HtcMock__NTasks=3000 \
  --env=HtcMock__TotalCalculationTime=00:10:00 \
  --env=HtcMock__SubTasksLevels=3 \
  --env=HtcMock__EnableFastCompute=false
```

From the workstation, through the NLB:

```sh
podman run --rm \
  -e GrpcClient__Endpoint=$(terraform output -json endpoints | jq -r .grpc) \
  -e HtcMock__Partition=htcmock \
  -e HtcMock__NTasks=3000 \
  -e HtcMock__TotalCalculationTime=00:10:00 \
  -e HtcMock__SubTasksLevels=3 \
  -e HtcMock__EnableFastCompute=false \
  docker.io/dockerhubaneo/armonik_core_htcmock_test_client:0.41.5
```

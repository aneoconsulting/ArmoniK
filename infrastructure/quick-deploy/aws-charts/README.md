# AWS quick deploy with the ArmoniK Helm charts

## Deployed by default

| | |
|---|---|
| Cluster | EKS 1.35, system node group 2x t3a.medium, Karpenter pools `core` (on-demand) and `workers` (spot first) |
| Network | VPC with one NAT gateway, NLB on `ingress_allowed_cidrs` |
| Storage | RDS PostgreSQL 18 db.t4g.large single-AZ, S3, SQS |
| ArmoniK | chart 0.17.0-SNAPSHOT.83, Core 0.41.4, chart sizing (1 control plane, 1 ingress), Prometheus, Grafana, Seq |
| Partitions | `htcmock` (scale to zero) and those of `k8s.tfvars` |

## Stack overrides

| | armonik69 | montparnasse |
|---|---|---|
| Region | eu-west-3 | us-east-2 |
| Partitions | `quantlib` (1 CPU, 512Mi, 0-20 pods) | `cpu` PymoniK worker (1 CPU, 2Gi, 8-48 pods) |

## armonik69

```sh
cd terraform/aws
terraform init -reconfigure -backend-config=../../stacks/armonik69/aws.tfbackend
terraform apply -var-file=../../stacks/armonik69/aws.tfvars

cd ../k8s
terraform init -reconfigure -backend-config=../../stacks/armonik69/k8s.tfbackend
terraform apply -var-file=../../stacks/armonik69/k8s.tfvars -var-file=../../stacks/armonik69/aws.tfbackend
```

## montparnasse

```sh
cd terraform/aws
terraform init -reconfigure -backend-config=../../stacks/montparnasse/aws.tfbackend
terraform apply -var-file=../../stacks/montparnasse/aws.tfvars

cd ../k8s
terraform init -reconfigure -backend-config=../../stacks/montparnasse/k8s.tfbackend
terraform apply -var-file=../../stacks/montparnasse/k8s.tfvars -var-file=../../stacks/montparnasse/aws.tfbackend
```

## HtcMock

```sh
podman run --rm \
  -e GrpcClient__Endpoint=http://$(kubectl -n armonik get svc armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5001 \
  -e HtcMock__Partition=htcmock \
  docker.io/dockerhubaneo/armonik_core_htcmock_test_client:0.41.4
```

## QuantLib (armonik69)

```sh
podman build -t armonik_quantlib_client:0.2.1 ../../../../ArmoniK.Samples/python/quantlib/client
podman run --rm -v ../../../../ArmoniK.Samples/python/quantlib/samples:/data/samples:ro \
  -e GrpcClient__Endpoint=http://$(kubectl -n armonik get svc armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5001 \
  armonik_quantlib_client:0.2.1 samples/mixed_batch.json --partition quantlib --batch-size 3
```

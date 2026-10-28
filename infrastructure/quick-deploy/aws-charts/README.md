# AWS quick deploy with the ArmoniK Helm charts

EKS + Karpenter, ArmoniK on RDS PostgreSQL, S3 and SQS, every image and chart through the ECR pull-through
cache. `terraform/aws` creates the AWS resources, then `terraform/k8s` the Helm releases.

## Setup

- `terraform/backend.tfbackend`: copy the `.example`, set the state bucket.
- `terraform/aws/registry-credentials.auto.tfvars`: copy the `.example`, fill in the Docker Hub and GitHub tokens.
- `terraform/aws/terraform.tfvars`: `prefix`.
- `terraform/k8s/terraform.tfvars`: `ingress_allowed_cidrs`, who may reach the NLB (`0.0.0.0/0`: everyone, no authentication).

## Deploy

```sh
cd terraform/aws
terraform init -backend-config=../backend.tfbackend
terraform apply

cd ../k8s
terraform init -backend-config=../backend.tfbackend
terraform apply -var-file=../backend.tfbackend   # finds the state of terraform/aws
```

## Access

```sh
aws eks update-kubeconfig --region eu-west-3 --name armonik69 --alias armonik69
kubectl get svc -n armonik armonik-ingress   # EXTERNAL-IP: the NLB
```

The NLB serves the API on 5001, and the GUI (`/admin/`), Grafana (`/grafana/`) and Seq (`/seq/`) on 5000.

## Update a worker

```sh
REPO=$(terraform -chdir=terraform/aws output -raw workers_repository)
aws ecr get-login-password | docker login --username AWS --password-stdin "${REPO%%/*}"
docker tag my-worker "$REPO:myapp-1.0.0" && docker push "$REPO:myapp-1.0.0"
```

Set the tag in `partitions` (`terraform/k8s/terraform.tfvars`), then in `terraform/k8s`:
`terraform apply -var-file=../backend.tfbackend`.

## Test

```sh
NLB=$(kubectl get svc -n armonik armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
docker run --rm -e HtcMock__NTasks=2000 -e HtcMock__TotalCalculationTime=02:00:00 -e HtcMock__SubTasksLevels=1 \
  -e HtcMock__Partition=htcmock -e GrpcClient__Endpoint=http://$NLB:5001 \
  dockerhubaneo/armonik_core_htcmock_test_client:0.41.3
```

## Destroy

The NLB and the Karpenter nodes belong to controllers: remove them first, while the controllers run.

```sh
cd terraform/k8s
terraform destroy -var-file=../backend.tfbackend -target=helm_release.armonik   # removes the NLB
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh                                            # wait until empty
terraform destroy -var-file=../backend.tfbackend

cd ../aws
terraform destroy
# Repositories created by the pull-through cache, outside the state
for r in $(aws ecr describe-repositories --output text \
    --query "repositories[?starts_with(repositoryName, 'armonik69/')].repositoryName"); do
  aws ecr delete-repository --repository-name "$r" --force > /dev/null
done
```

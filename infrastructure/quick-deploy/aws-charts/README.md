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

## Add a partition

Any ECR repository of the account works, not only `workers_repository` and not only the pull-through cache:
the nodes pull with `AmazonEC2ContainerRegistryReadOnly`. A repository encrypted with a customer KMS key
also needs `kms:Decrypt` for the node roles (`terraform -chdir=terraform/aws output node_role_arns`).

1. Push the image, with a new tag for every version (a re-pushed tag is not pulled again):

   ```sh
   REPO=123456789012.dkr.ecr.eu-west-3.amazonaws.com/my-team/my-worker   # or: terraform -chdir=terraform/aws output -raw workers_repository
   aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin "${REPO%%/*}"
   docker tag my-worker "$REPO:1.0.0" && docker push "$REPO:1.0.0"
   ```

2. Declare it in `terraform/k8s/terraform.tfvars` (name: lowercase letters and digits only):

   ```hcl
   partitions = {
     myapp = {
       image        = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/my-team/my-worker"   # without the tag
       tag          = "1.0.0"
       cpu          = "2"       # worker requests = limits
       memory       = "4Gi"
       max_replicas = 50        # KEDA scales from 0 to this
     }
   }
   ```

3. Apply, then check:

   ```sh
   cd terraform/k8s && terraform apply -var-file=../backend.tfbackend
   kubectl get scaledobject -n armonik armonik-compute-plane-myapp   # READY True
   ```

The partition runs no pod until tasks arrive: submit to partition `myapp`, then watch
`kubectl get pods -n armonik -l armonik.fr/partition=myapp`. An `ImagePullBackOff` means a wrong image path or
tag, or a repository policy or KMS key that refuses the node roles.

To update a worker, push a new tag, change `tag` and apply again: the partition's pods roll over.

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

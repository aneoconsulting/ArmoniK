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

Every command works in bash, zsh and fish (3.4+). From this folder, after the `terraform apply` of
`terraform/aws` (`.kubeconfig` is git-ignored):

```sh
aws eks update-kubeconfig --region eu-west-3 --name armonik69 --alias armonik69 --kubeconfig .kubeconfig
kubectl get svc -n armonik armonik-ingress   # EXTERNAL-IP: the NLB
```

The NLB serves the API on 5001, and the GUI (`/admin/`), Grafana (`/grafana/`) and Seq (`/seq/`) on 5000.

## Add a partition

Any ECR repository of the account works, not only `workers_repository` and not only the pull-through cache:
the nodes pull with `AmazonEC2ContainerRegistryReadOnly`. A repository encrypted with a customer KMS key
also needs `kms:Decrypt` for the node roles (`terraform -chdir=terraform/aws output node_role_arns`).

1. Push the image, with a new tag for every version (a re-pushed tag is not pulled again):

   ```sh
   # Repository: yours, or terraform -chdir=terraform/aws output -raw workers_repository
   aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-3.amazonaws.com
   docker tag my-worker 123456789012.dkr.ecr.eu-west-3.amazonaws.com/my-team/my-worker:1.0.0
   docker push 123456789012.dkr.ecr.eu-west-3.amazonaws.com/my-team/my-worker:1.0.0
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
docker run --rm -e HtcMock__NTasks=2000 -e HtcMock__TotalCalculationTime=02:00:00 -e HtcMock__SubTasksLevels=3 \
  -e HtcMock__Partition=htcmock \
  -e GrpcClient__Endpoint=http://$(kubectl get svc -n armonik armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5001 \
  dockerhubaneo/armonik_core_htcmock_test_client:0.41.3
```

HtcMock submits one root task that creates all the others as subtasks: nothing runs while the agent uploads
their payloads (~170 ms each, one after the other, ~6 min for 2000). The Bench client submits its tasks
directly, to the `bench` partition of `terraform/k8s/terraform.tfvars`: 10 000 tasks of 100 ms, a few minutes
and a few cents of spot nodes.

```sh
docker run --rm -e BenchOptions__NTasks=10000 -e BenchOptions__TaskDurationMs=100 \
  -e BenchOptions__Partition=bench -e BenchOptions__DegreeOfParallelism=8 \
  -e GrpcClient__Endpoint=http://$(kubectl get svc -n armonik armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5001 \
  dockerhubaneo/armonik_core_bench_test_client:0.41.3
```

## Destroy

The NLB and the Karpenter nodes belong to controllers: remove them first, while the controllers run. The
External Secrets objects (`postgresql-connection`, `aws-secret-store`) and the operators go first too: once the
node pools are gone, External Secrets has no node left, and its webhooks and finalizers block their deletion.

```sh
cd terraform/k8s
terraform destroy -var-file=../backend.tfbackend \
  -target=helm_release.armonik -target=helm_release.postgresql_connection \
  -target=helm_release.aws_secret_store -target=helm_release.armonik_operators   # removes the NLB
kubectl get svc -A | grep LoadBalancer                                          # wait until empty
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh                                            # wait until empty
terraform destroy -var-file=../backend.tfbackend

cd ../aws
terraform destroy
# Repositories created by the pull-through cache, outside the state
aws ecr describe-repositories --output text \
    --query "repositories[?starts_with(repositoryName, 'armonik69/')].repositoryName" \
  | xargs -rn1 aws ecr delete-repository --force --output text --query repository.repositoryName --repository-name
# Queues Core created for the partitions that ran, outside the state too
aws sqs list-queues --queue-name-prefix armonik69 --query 'QueueUrls' --output text \
  | xargs -rn1 aws sqs delete-queue --queue-url
```

If the node pools went first anyway, `terraform destroy` fails with `Unable to uninstall Helm release
postgresql-connection` (or `aws-secret-store`): the External Secrets webhooks have no pod to answer. Remove them,
and the finalizer only the stopped controller would clear, then destroy again:

```sh
kubectl delete validatingwebhookconfiguration externalsecret-validate secretstore-validate
kubectl -n armonik patch externalsecret armonik-postgresql-connection --type=merge -p '{"metadata":{"finalizers":null}}'
```

## PostgreSQL connection options

Core builds its Npgsql connection string itself and exposes no option for connection pooling or prepared
statements. `postgresql_connection_options` (`terraform/k8s/terraform.tfvars`) passes them anyway:

1. The local chart `charts/postgresql-connection` (release `postgresql-connection`, namespace `armonik`) holds
   one `ExternalSecret`. ESO reads the RDS master user secret through the `aws-secrets-manager`
   ClusterSecretStore and writes the Secret `armonik-postgresql-connection`, key `connectionString`:
   `Host=…;Port=…;Database=armonik;Username=…;Password='…';<options>`. A password rotation is carried over at the
   next sync (1 h), and the pods pick it up at their next start.
2. The `armonik` release then sets `PostgreSQL__ConnectionString` from that Secret (`conf.core.envFromSecret`).
   With it, Core ignores its own Host, User and Password settings. TLS is unchanged: Core still requires SSL and
   validates RDS against the CA.

Empty option string: no chart, Core's own connection string. Core reads it at startup only, so after a change:

```sh
kubectl -n armonik rollout restart deploy -l 'app.kubernetes.io/name in (control-plane,compute-plane)'
```

What the options do:

| Option | Effect |
|---|---|
| `No Reset On Close=true` | Skips the `DISCARD ALL` Npgsql sends by default on every connection returned to its pool (about 10 per task), which wipes the session state so the next user does not inherit it. Core keeps none (no `SET`, no session lock, no temp table), so the reset only threw away the cached plans |
| `Max Auto Prepare=100` | Npgsql keeps up to 100 prepared statements per connection: PostgreSQL plans a query once instead of at every call. Core runs about 30 queries per task, always the same ones |
| `Auto Prepare Min Usages=2` | A query is prepared from its second run on |

The PostgreSQL versus MongoDB benchmark measured +46 % throughput with the three together, +7 % with the first
one alone. To check they apply, during a run: `DISCARD ALL` disappears from `pg_stat_statements`, and
`total_plan_time` drops (`pg_stat_statements.track_planning` is on, see `terraform/aws/rds.tf`).

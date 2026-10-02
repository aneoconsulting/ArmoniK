# AWS quick deploy with the ArmoniK Helm charts

Deploys ArmoniK on AWS in two layers:

- **Terraform** (`terraform/`) creates the AWS infrastructure only: VPC, EKS, Karpenter's IAM and
  interruption queue, RDS PostgreSQL, the S3 object storage, the ECR pull-through cache and the EKS
  Pod Identity roles. It configures no Kubernetes or Helm provider.
- **helmfile** (`helmfile.yaml.gotmpl`) deploys everything that runs in the cluster, from the
  Terraform outputs: Karpenter and its node pools, the AWS Load Balancer Controller, the
  `armonik-operators` release, then the `armonik` release. [docs/helm-cli.md](docs/helm-cli.md)
  gives the same deployment with plain `helm` commands.

## Architecture

| Concern | Choice |
|---|---|
| Nodes | A small managed node group (`system`, tainted `CriticalAddonsOnly`) for Karpenter and CoreDNS; everything else on Karpenter node pools |
| Node pools | `core` (on-demand; control plane, ingress, operators, monitoring) and `workers` (spot first, tainted; compute plane only) |
| Table storage | RDS PostgreSQL with logical replication (Core's task and result watchers stream the WAL) |
| Object storage | S3, SSE-KMS with a bucket key |
| Queue | SQS, the queues being created by Core under the `dependencies.sqs.prefix` of the chart |
| Credentials | EKS Pod Identity for the AWS APIs; the RDS master password stays in Secrets Manager and reaches the pods through the External Secrets Operator |
| Images and charts | Everything is pulled through the ECR pull-through cache (Docker Hub, GHCR, Quay, registry.k8s.io, ECR Public) |
| Ingress | The ArmoniK nginx ingress behind an internet-facing NLB |
| Monitoring | The charts' own: kube-prometheus-stack, Grafana, fluent-bit, Seq |

## Requirements

- AWS CLI, Terraform >= 1.11, helm, [helmfile](https://helmfile.readthedocs.io/) with the
  [helm-diff](https://github.com/databus23/helm-diff) plugin, kubectl, jq.
- A Docker Hub account and a GitHub account with a token: AWS requires upstream credentials to cache
  these two registries. A read-only Docker Hub access token and a classic GitHub token with the
  `read:packages` scope are enough.

```sh
export DOCKER_HUB_USERNAME=... DOCKER_HUB_TOKEN=...
export GITHUB_USERNAME=... GITHUB_TOKEN=...
```

They are written to Secrets Manager as Terraform write-only values, so they never reach the state.
Only the first deploy needs them exported: afterwards the Makefile reads them back from Secrets
Manager. To change them, export new values and bump `registry_credentials_version`.

## Deploy

The Terraform state goes to an S3 bucket you already have: copy `backend.tfbackend.example` to
`backend.tfbackend` (git-ignored) and set its `bucket` and `region`. The Makefile adds the key,
`<PREFIX>/armonik-terraform.tfstate`, so one bucket can hold many deployments.

```sh
make deploy             # terraform apply, then helmfile apply
export KUBECONFIG=$PWD/generated/kubeconfig AKCONFIG=$PWD/generated/armonik-cli.yaml
```

The infrastructure parameters live in `parameters.tfvars`; see `terraform/variables.tf` for all of
them. `make help` lists the targets and variables below.

| Target | Does |
|---|---|
| `make deploy` | `init`, `apply`, `output`, `kubeconfig`, `registry-login`, `charts`, `cliconfig` |
| `make destroy` | `init`, `output`, `kubeconfig`, then `delete` |
| `make init` | Terraform init against the state backend |
| `make plan` / `make apply` | Terraform plan / apply |
| `make output` | Writes the Terraform outputs, read by the helmfile, to `generated/armonik-output.json` |
| `make kubeconfig` | Writes the cluster kubeconfig to `generated/kubeconfig` |
| `make kubie` | Writes the cluster kubeconfig to `~/.kube/<cluster>.yaml`, for kubie |
| `make registry-login` | Logs helm in to ECR. The token lasts 12 h: rerun it when a chart pull returns 403 |
| `make charts` / `make charts-diff` | Applies / diffs the helmfile |
| `make check-images` | Fails if a rendered image does not come from the pull-through cache |
| `make cliconfig` | Writes the ArmoniK CLI configuration (NLB endpoint) to `generated/armonik-cli.yaml` |
| `make charts-destroy` | Removes the charts in reverse order, waiting for the NLB and the Karpenter nodes |
| `make delete` | `charts-destroy`, `terraform destroy`, then `clean-ecr` |
| `make clean-ecr` | Deletes the repositories created by the pull-through cache, which are outside the Terraform state |
| `make clean` | Removes the local Terraform data (providers, modules, lock file) |
| `make env` | Prints the environment make runs with |

| Variable | Default | Purpose |
|---|---|---|
| `PROFILE` | `AWS_PROFILE`, required | AWS CLI profile |
| `REGION` | `eu-west-3` | AWS region |
| `PREFIX` | `armonik-<random>`, kept in `generated/.prefix` | Name prefix of every resource, and of the state key |
| `NAMESPACE` | `armonik` | Namespace of the ArmoniK release |
| `BACKEND_CONFIG` | `backend.tfbackend` | Terraform backend configuration |
| `PARAMETERS_FILE` | `parameters.tfvars` | Terraform variables |
| `KUBIE_DIR` | `~/.kube` | Where `make kubie` writes |
| `ARMONIK_CHART_VERSION`, `ARMONIK_CHARTS_DIR` | | See [ArmoniK charts version](#armonik-charts-version) |

## Running a test

The htcmock client runs in the cluster and reaches the control plane through its service, its image
coming through the cache with the Core version of the release:

```sh
export KUBECONFIG=$PWD/generated/kubeconfig
DOCKER_HUB=$(jq -r .registry.upstreams.dockerHub generated/armonik-output.json)
CORE=$(helm get values armonik -n armonik -o json | jq -r .global.armonik.versions.core)

kubectl run htcmock-client -n armonik --rm -i --restart=Never \
  --image="$DOCKER_HUB/dockerhubaneo/armonik_core_htcmock_test_client:$CORE" \
  --env=HtcMock__NTasks=20000 \
  --env=HtcMock__TotalCalculationTime=02:00:00 \
  --env=HtcMock__DataSize=1 \
  --env=HtcMock__MemorySize=1 \
  --env=HtcMock__EnableFastCompute=false \
  --env=HtcMock__SubTasksLevels=1 \
  --env=HtcMock__Partition=htcmock \
  --env=GrpcClient__Endpoint=http://armonik-control-plane:5001
```

`TotalCalculationTime` is the compute time of all the tasks together, here about 0.36s per task,
and only spent with `EnableFastCompute=false`. The queue stays long enough for KEDA to scale the
`htcmock` partition up to its 50 pods (`compute-plane.partitionCommon.hpa.maxReplicaCount`), and for
Karpenter to add the worker nodes. To watch it:

```sh
kubectl get pods -n armonik -l armonik.fr/partition=htcmock -w
kubectl get nodeclaims -w
eks-node-viewer --node-selector armonik.aneo.fr/node-pool=workers
```

Once the queue is empty, KEDA scales the partition to 0 after its cooldown (5 minutes), and Karpenter
removes the empty worker nodes a minute later.

From outside the cluster, the same client targets the NLB on port 5001 (`endpoint` in
`generated/armonik-cli.yaml`).

## ArmoniK charts version

The ArmoniK charts are pinned in `helmfile.yaml.gotmpl` and pulled, through the cache, from
`dockerhubaneo` on Docker Hub, where CI publishes every ArmoniK.Infra branch as
`<version>-<branch>.<n>.sha.<commit>`. Two overrides:

```sh
make charts ARMONIK_CHART_VERSION=0.16.0-SNAPSHOT.294.sha.51d18a25    # another published version
make charts ARMONIK_CHARTS_DIR=~/ArmoniK.Infra/charts                  # a local checkout
```

A local checkout needs its dependencies vendored first (`charts/update-charts.sh` in ArmoniK.Infra).

## Sizing the compute plane

The compute plane chart defaults are Burstable (`requests` below `limits`). Here
`values/armonik.yaml.gotmpl` sets `requests` equal to `limits` for both the polling agent and the
worker. The pods are then Guaranteed: a dedicated CPU share, evicted last, and sized exactly by
Karpenter, which picks instances from the pods' requests.

Per-partition overrides, and any other value, go in `values/local.yaml` (git-ignored), which the
helmfile layers over the ArmoniK values when it exists:

```yaml
compute-plane:
  partitions:
    htcmock:
      worker:
        resources:
          requests: {cpu: "2", memory: 4Gi}
          limits: {cpu: "2", memory: 4Gi}
```

Compute pods carry `karpenter.sh/do-not-disrupt`, and the `workers` node pool only consolidates
empty nodes: Karpenter never evicts a running task. Spot interruptions still do, and ArmoniK retries
the task.

## Known limits

- **RDS password rotation**: RDS rotates the master password it manages, here every
  `rds.password_rotation_days` (365 by default). ESO refreshes the Kubernetes Secret within the hour,
  but the ArmoniK pods only read it at startup: restart them after a rotation.
- **PostgreSQL connections**: every control-plane and polling-agent pod has its own connection pool
  (`PostgreSQL__MaxPoolSize`, 100 by default). Size `max_connections` (derived from the instance class
  by RDS) against the maximum number of compute pods, or lower the pool size.
- **Replication slots**: each control-plane pod serving the events API holds up to two logical
  replication slots; `rds.max_replication_slots` (20) covers about ten replicas.
- **AWS Load Balancer Controller chart**: published on an HTTP repository only, so it is the one chart
  not pulled through the cache (its image is).

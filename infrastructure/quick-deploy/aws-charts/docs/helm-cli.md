# Deploying the charts with the helm CLI

Terraform (`make init apply`) creates the AWS infrastructure. Everything that runs in the cluster is then six
helm releases, installed here by hand with `helm` alone: no helmfile, and the Makefile is only used for
Terraform. The values files are in [examples/values](examples/values), the variables they read in
[examples/env.sh](examples/env.sh).

The example values are a **customer scenario**: charts and images from a private registry (Artifactory),
Valkey in the cluster for the objects, RDS PostgreSQL for the tasks, SQS for the queue, and the customer's
own Grafana. [Customer scenario](#customer-scenario) says where each choice lives, and
[Advice](#advice-for-a-customer-deployment) lists what to harden.

## The releases

| # | Release | Chart | Namespace | Needs | What it is |
|---|---|---|---|---|---|
| 1 | `karpenter` | `karpenter/karpenter` (OCI, `public.ecr.aws`) | `kube-system` | the EKS cluster | Starts and stops EC2 nodes after the pending pods |
| 2 | `karpenter-nodes` | `charts/karpenter-nodes` (local) | `kube-system` | 1 (the CRDs) | One `EC2NodeClass`, the `NodePool`s `core`, `workers`, `storage`, and the default `gp3` `StorageClass` |
| 3 | `aws-load-balancer-controller` | `eks/aws-load-balancer-controller` (HTTP repo, `EKS_CHARTS_URL`) | `kube-system` | 2 (nodes to run on) | Turns a `Service` of type `LoadBalancer` into an NLB |
| 4 | `armonik-operators` | `armonik-operators` (OCI, Docker Hub) | `armonik-operators` | 3 | Install-once operators: External Secrets, KEDA, cert-manager, kube-prometheus-stack |
| 5 | `aws-secret-store` | `charts/aws-secret-store` (local) | `armonik-operators` | 4 (the ESO CRDs) | A `ClusterSecretStore` on AWS Secrets Manager |
| 6 | `armonik` | `armonik` (OCI, Docker Hub) | `armonik` | 3, 4, 5 | Control plane, compute plane, ingress, Valkey, Seq, fluent-bit, and the custom resources of the operators |

Each release needs the previous ones to be ready, hence `--wait`. The order is the one of
`helmfile.yaml.gotmpl`, which is the same list.

Optionally, a `cilium` release comes first, to enforce NetworkPolicies: see [4.0](#40-cilium-optional).

## Prerequisites

`helm` (3.8 or later, for OCI), `kubectl`, `aws`, `jq`, `terraform`, and `envsubst` (package `gettext`). The
infrastructure is up and your AWS profile works:

```sh
export AWS_PROFILE=<your-profile>  # same profile as for make
make init apply                   # in aws-charts/, creates the infrastructure only
```

The first `make apply` needs the Docker Hub and GitHub credentials of the pull-through cache, see the
[README](../README.md#requirements). With a registry of your own (Artifactory) the cache is still created:
it simply stays unused.

## 1. Inputs: the Terraform outputs

The values files hold `${VARIABLE}` placeholders. `examples/env.sh` fills them from `terraform output -json`
(the outputs are in `terraform/outputs.tf`), so nothing depends on the helmfile:

```sh
cd ArmoniK/infrastructure/quick-deploy/aws-charts
source docs/examples/env.sh
```

It reads `terraform -chdir=terraform output -json`, which needs the backend initialized by `make init` (the
Makefile keeps that data in `generated/`, hence `TF_DATA_DIR`, which `env.sh` defaults to it). To work from
a saved copy, or without access to the state, `export TF_OUTPUT_JSON=outputs.json` first.

| Variable | Terraform output | Used by | Without our Terraform |
|---|---|---|---|
| `CLUSTER_NAME`, `AWS_REGION`, `VPC_ID` | `eks.{name,region,vpc_id}` | Karpenter, AWS LB Controller | Your EKS cluster and its VPC |
| `ARMONIK_NS`, `OPERATORS_NS` | `namespaces.{armonik,operators}` | all of them | Free, **but** see the note below |
| `SA_CONTROL_PLANE`, `SA_COMPUTE_PLANE` | `service_accounts.*` | `armonik` | Free, **but** see the note below |
| `KARPENTER_NODE_ROLE` | `karpenter.node_role` | `karpenter-nodes` | IAM role of the nodes Karpenter starts |
| `KARPENTER_QUEUE` | `karpenter.queue_name` | `karpenter` | SQS queue of the interruption events |
| `KARPENTER_DISCOVERY_TAG` | `karpenter.discovery_tag` | `karpenter-nodes` | Value of the `karpenter.sh/discovery` tag on your subnets and node security group |
| `PG_HOST`, `PG_PORT`, `PG_DATABASE` | `postgresql.{host,port,database}` | `armonik` | Any PostgreSQL with logical replication on |
| `PG_SECRET_ARN` | `postgresql.secret_arn` | `armonik` | A Secrets Manager secret `{"username","password"}`, or a Kubernetes Secret (see the values file) |
| `SQS_PREFIX` | `queue.prefix` | `armonik` | Any prefix; the IAM policy must cover `<prefix>*` |
| `S3_BUCKET` | `object_storage.bucket` | `armonik` (variant) | Any bucket |
| `REG_DOCKERHUB`, `REG_GHCR`, `REG_QUAY`, `REG_K8S`, `REG_ECR_PUBLIC` | `registry.upstreams.*` | all of them | Your registry, one prefix per upstream (see [Registries](#2-registries)) |

The names after "Free, but" are not free to choose: the service accounts, and the ESO (`external-secrets`),
Karpenter and AWS Load Balancer Controller ones, are bound to IAM roles by **EKS Pod Identity**, by namespace
and name (`terraform/identities.tf`). The AWS APIs are reached without any secret, and renaming one of them
without changing the association leaves the pod without credentials.

Render the values once, into `generated/` (git-ignored):

```sh
mkdir -p generated/values
for f in docs/examples/values/*.yaml; do
  envsubst "$ENVSUBST_VARS" < "$f" > "generated/values/$(basename "$f")"
done
grep -l '\${' generated/values/*.yaml            # nothing: every placeholder was filled
export KUBECONFIG=$PWD/generated/kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" --kubeconfig "$KUBECONFIG"
V=generated/values
```

## 2. Registries

Every chart and every image is pulled from a registry of your choice: the files only contain the five
`REG_*` prefixes, one per upstream, because Docker Hub, GHCR, Quay and the others do not share a namespace.

| Upstream | Used for |
|---|---|
| `registry-1.docker.io` | the ArmoniK charts and images, Seq, fluent-bit, the `busybox` of the CRD upgrade job |
| `ghcr.io` | External Secrets, KEDA, kube-webhook-certgen, configmap-reload, the Valkey exporter |
| `quay.io` | cert-manager, Prometheus, its operator and node-exporter |
| `registry.k8s.io` | kube-state-metrics |
| `public.ecr.aws` | Karpenter, the AWS Load Balancer Controller image, Valkey |

### A. The ECR pull-through cache (the quick deploy default)

Terraform created one cache rule per upstream, so `env.sh` already points at it. Helm only needs to log in
(the token lasts 12 hours: log in again on a 403):

```sh
REGISTRY_HOST=${REG_DOCKERHUB%%/*}
aws ecr get-login-password --region "$AWS_REGION" | helm registry login --username AWS --password-stdin "$REGISTRY_HOST"
```

The AWS Load Balancer Controller chart is the one thing the cache cannot serve, being published on an HTTP
repository only (its image does come through the cache).

### B. Artifactory

Create one remote repository per upstream of the table above (type Docker, path-based access, which is the
default), and two Helm OCI remotes for the charts. In `env.sh`, replace the `REG_*` and `CHARTS_*` lines by
the commented Artifactory block, with your host and repository keys:

```sh
export ARTIFACTORY=artifactory.example.com
export REG_DOCKERHUB=$ARTIFACTORY/docker-hub-remote
export REG_GHCR=$ARTIFACTORY/ghcr-remote
export REG_QUAY=$ARTIFACTORY/quay-remote
export REG_K8S=$ARTIFACTORY/k8s-remote
export REG_ECR_PUBLIC=$ARTIFACTORY/ecr-public-remote
export CHARTS_DOCKERHUB=$ARTIFACTORY/dockerhub-helm-remote
export CHARTS_ECR_PUBLIC=$ARTIFACTORY/ecr-public-helm-remote
export EKS_CHARTS_URL=https://$ARTIFACTORY/artifactory/api/helm/eks-helm-remote
```

The last one is not OCI: the AWS Load Balancer Controller chart is on a classic Helm repository
(`https://aws.github.io/eks-charts`), so it needs a **Helm** remote repository in Artifactory pointing to that
URL, and the URL helm reads is `https://<host>/artifactory/api/helm/<repository key>`. Without it, step
[4.3](#43-aws-load-balancer-controller) goes to the Internet.

The image paths then read `artifactory.example.com/docker-hub-remote/dockerhubaneo/armonik_control:<tag>`.
With a sub-domain access method (`docker-hub-remote.artifactory.example.com/...`), only these prefixes change.
No remote repository for an upstream, or an air-gapped Artifactory? Copy what you need into a local
repository instead. For the charts, keep the path the commands below expect:

```sh
helm pull "oci://registry-1.docker.io/dockerhubaneo/armonik" --version "$ARMONIK_VERSION"
helm push "armonik-$ARMONIK_VERSION.tgz" "oci://$ARTIFACTORY/helm-local/dockerhubaneo"   # CHARTS_DOCKERHUB=$ARTIFACTORY/helm-local
helm pull "oci://public.ecr.aws/karpenter/karpenter" --version "$KARPENTER_VERSION"
helm push "karpenter-$KARPENTER_VERSION.tgz" "oci://$ARTIFACTORY/helm-local/karpenter"   # CHARTS_ECR_PUBLIC=$ARTIFACTORY/helm-local
```

Do the same for `armonik-operators`, and mirror the images that `helm template` lists
([Check before installing](#3-check-before-installing)) under the `REG_*` paths.

Log helm in, and give the cluster the credentials:

```sh
helm registry login "$ARTIFACTORY" --username "$ARTIFACTORY_USER" --password-stdin <<< "$ARTIFACTORY_TOKEN"

for ns in kube-system "$OPERATORS_NS" "$ARMONIK_NS"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret docker-registry registry-credentials -n "$ns" \
    --docker-server="$ARTIFACTORY" --docker-username="$ARTIFACTORY_USER" --docker-password="$ARTIFACTORY_TOKEN"
done
```

Then uncomment the `imagePullSecrets` blocks of `karpenter.yaml`, `aws-load-balancer-controller.yaml`,
`armonik-operators.yaml` (one key per subchart, each chart names it differently), and use
`armonik-registry-auth.yaml`, which sets them for `armonik`. To avoid a Secret per namespace and one key per chart, give
the nodes the credentials instead (the container runtime configuration, or a kubelet image credential
provider, set in the `userData` of the EC2NodeClass: `nodeClass.userData` in `charts/karpenter-nodes/values.yaml`).

## 3. Check before installing

Everything below is local: nothing reaches the cluster.

```sh
helm template armonik "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" \
  -n "$ARMONIK_NS" -f $V/armonik.yaml -f $V/armonik-registry-auth.yaml -f $V/armonik-hardening.yaml > /tmp/armonik.yaml
helm template armonik-operators "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik-operators" --version "$ARMONIK_VERSION" \
  -n "$OPERATORS_NS" -f $V/armonik-operators.yaml --include-crds=false > /tmp/operators.yaml

# Fails on an image outside the registry (the argument is the prefix every image must start with)
sh scripts/check-images.sh "${REG_DOCKERHUB%%/*}" < /tmp/armonik.yaml
sh scripts/check-images.sh "${REG_DOCKERHUB%%/*}" < /tmp/operators.yaml
```

A chart that renders is not an installed chart, but this catches the mistakes of a values file: the template
refuses two table backends, an `ingress.mtls` without `ingress.tls`, a missing RDS host. To see every image
the charts will pull, for the mirroring above: `grep -E 'image:' /tmp/armonik.yaml | sort -u`.

## 4. Install

The same commands whichever registry: only `CHARTS_*` and the values change. `--install` makes each command
safe to rerun. Do not add `--reuse-values`: the next upgrade would replay the old coalesced values and
ignore the new defaults of the chart.

### 4.0 Cilium (optional)

Only to enforce NetworkPolicies (`networkPolicy.enabled` in `armonik-hardening.yaml`), or to use Hubble. Cilium
is **chained** on the AWS VPC CNI, which keeps assigning the pod IP addresses: the NLB with
`nlb-target-type: ip` and Pod Identity keep working, and the `vpc-cni` addon stays in `terraform/eks.tf`.

```sh
helm repo add cilium https://helm.cilium.io && helm repo update cilium
helm upgrade --install cilium cilium/cilium --version "$CILIUM_VERSION" \
  -n kube-system -f $V/cilium.yaml --wait
kubectl -n kube-system rollout status ds/cilium
```

Install it before everything else: a pod started before Cilium is not covered by the policies until it is
restarted. Do not remove the `vpc-cni` addon (the "replace the CNI" modes need extra IAM rights, a Karpenter
`startupTaint`, and leave the managed node group stuck until Cilium is installed). To only enforce the
policies, without Hubble, `enableNetworkPolicy` on the `vpc-cni` addon is simpler (see
[Customer scenario](#customer-scenario)).

With Artifactory, add a Helm remote repository for `https://helm.cilium.io` (like the one for `eks-charts`).
The `quay.io/cilium/*` images go through the `REG_QUAY` remote, which `$V/cilium.yaml` already uses.

### 4.1 Karpenter

```sh
helm upgrade --install karpenter "oci://$CHARTS_ECR_PUBLIC/karpenter/karpenter" --version "$KARPENTER_VERSION" \
  -n kube-system -f $V/karpenter.yaml --wait
```

The controller runs on the small `system` managed node group Terraform created, never on a node it manages.
It reads `settings.clusterName` and the SQS queue of the spot interruption events, and calls EC2 with the
Pod Identity role of `kube-system/karpenter`. This release also installs the `NodePool` and `EC2NodeClass`
CRDs.

### 4.2 The node pools

```sh
helm upgrade --install karpenter-nodes ./charts/karpenter-nodes -n kube-system -f $V/karpenter-nodes.yaml --wait
```

This chart is ours: the EC2NodeClass (AL2023, 50 GiB gp3 encrypted, IMDS hop limit 1 so that pods use Pod
Identity and never the node role) and three NodePools, selected by the label `armonik.aneo.fr/node-pool`:

| Pool | Capacity | For | Policy |
|---|---|---|---|
| `core` | on-demand | control plane, ingress, operators, monitoring | consolidated after 5 min when underused |
| `workers` | spot first, tainted | compute plane only | only empty nodes are removed: a running task is never evicted |
| `storage` | on-demand `r` class, tainted | Valkey | removed only when empty |

Show it: `kubectl get nodepools,ec2nodeclass` (no node yet: Karpenter starts one when a pod needs it).

### 4.3 AWS Load Balancer Controller

```sh
# With Artifactory, add --username "$ARTIFACTORY_USER" --password "$ARTIFACTORY_TOKEN" (and --ca-file for a private CA)
helm repo add eks "$EKS_CHARTS_URL" && helm repo update eks
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version "$LBC_VERSION" \
  -n kube-system -f $V/aws-load-balancer-controller.yaml --wait
```

The ingress `Service` carries `aws-load-balancer-type: external` annotations: the controller, not the
in-tree cloud provider, then creates the NLB and registers the pod IPs (`nlb-target-type: ip`). It must exist
before `armonik`, and its webhook before anything creates a `Service`.

### 4.4 The operators

```sh
helm upgrade --install armonik-operators "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik-operators" \
  --version "$ARMONIK_VERSION" -n "$OPERATORS_NS" --create-namespace -f $V/armonik-operators.yaml \
  --wait --timeout 10m
```

Four operators and their CRDs, installed once per cluster and never inside the application release, so that
`helm uninstall armonik` cannot delete a CRD and with it every custom resource of the cluster. PostgreSQL and
MongoDB operators are switched off: the database is RDS. Karpenter provisions the nodes they run on, so the
first run takes a few minutes.

```sh
kubectl get pods -n "$OPERATORS_NS"
```

### 4.5 The secret store

```sh
helm upgrade --install aws-secret-store ./charts/aws-secret-store -n "$OPERATORS_NS" -f $V/aws-secret-store.yaml --wait
kubectl get clustersecretstore aws-secrets-manager        # READY True
```

One `ClusterSecretStore` and no `auth` block: ESO calls Secrets Manager with the Pod Identity of its own
service account `external-secrets`, whose role Terraform restricted to the RDS secret. `armonik` refers to the
store by its name and reads the RDS password through an `ExternalSecret`. It is a separate release because the
`ClusterSecretStore` kind exists only once the previous release has installed the CRDs.

### 4.6 ArmoniK

```sh
helm upgrade --install armonik "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" \
  -n "$ARMONIK_NS" --create-namespace -f $V/armonik.yaml -f $V/armonik-registry-auth.yaml -f $V/armonik-hardening.yaml \
  --wait --timeout 15m          # no --wait-for-jobs: see below
```

The three files are layers, merged in order (the last one wins): `armonik.yaml` is the base, and the other two
are optional. Leave `armonik-registry-auth.yaml` out with the ECR cache (no pull secret needed), and
`armonik-hardening.yaml` out for a first run (internet-facing NLB, no TLS, no NetworkPolicies). Each only holds
what changes.

Do not add `--wait-for-jobs`: the init Jobs set `ttlSecondsAfterFinished: 1`, so they are deleted before helm
looks at them and the release would fail with `jobs.batch ... not found`.

```sh
kubectl get pods -n "$ARMONIK_NS"
kubectl get svc -n "$ARMONIK_NS" armonik-ingress          # EXTERNAL-IP, the NLB
```

The compute plane starts at zero pod: KEDA scales a partition on its queue, and Karpenter adds the worker
nodes. [README, "Running a test"](../README.md#running-a-test) runs a workload that shows both.

## Customer scenario

What each choice of `examples/values/armonik.yaml` is, and what changes with it.

| Choice | Where | Notes |
|---|---|---|
| Private registry | the `REG_*` variables, `registry:` / `repository:` of every image | The ArmoniK images are `dockerhubaneo/*`: with your own build, change `repository` per partition. `global.imageRegistry` overrides *every* registry at once, but only the charts that implement it honour it (not the other dependencies, Valkey and Seq among them), hence the explicit per-image values. |
| RDS PostgreSQL | `dependencies.externalPostgresql`, `mongodb.enabled: false` | One table backend per deployment. Logical replication must be on (`rds.logical_replication`, `terraform/rds.tf`): Core's task and result watchers stream the WAL. The credentials go through ESO from the secret RDS manages; for a Secret of your own, drop `storeName`/`storeKind` and name a Kubernetes Secret with `username` and `password` keys. |
| Valkey in the cluster | `dependencies.redis`, `s3.enabled: false` | Objects live in memory, with no persistence: a restart loses them. Dedicated `storage` node pool, `requests == limits`, `maxmemory` below the limit. For durable objects use S3 instead: `redis.enabled: false`, `s3.enabled: true` (the Pod Identity policy already grants the bucket). |
| SQS | `dependencies.sqs` | Core creates the queues, named after the prefix. The IAM policy covers `<prefix>*` only, so a different prefix needs a policy change. `activemq` and `rabbitmq` stay off: one queue per deployment. |
| Prometheus | `global.armonik.monitoring.prometheusUrl` | The operators' Prometheus: the Grafana datasource, and the PromQL KEDA triggers. The default scaling path reads the metrics exporter of the control plane instead. |
| Customer's Grafana | `dependencies.grafana.enabled: false`, `ingress.grafana_url` | See [examples/grafana-dashboards.md](examples/grafana-dashboards.md): the chart then renders neither the datasource nor the dashboards. |
| Ingress, TLS, mTLS | `ingress.service.annotations`, `armonik-hardening.yaml` | `tls.enabled` terminates TLS in nginx, with a certificate from cert-manager; `mtls.enabled` also demands a client certificate signed by a CA cert-manager creates. Clients then connect to the NLB over TLS. |
| NetworkPolicies | `networkPolicy.enabled` | The umbrella's policies. They are enforced only if the CNI enforces them: on the EKS VPC CNI, `enableNetworkPolicy` must be set on the addon (`terraform/eks.tf` does not set it), or install Cilium in chaining mode ([4.0](#40-cilium-optional)). |

## Advice for a customer deployment

- **Pin everything.** `--version` on every chart, `global.armonik.versions.core` and `.gui` in the values (an
  empty value follows the chart's `appVersion`), chart and images mirrored in the registry they use. Promote the
  same values files from one environment to the next, with a different `env.sh` each.
- **Do not put secrets in values files.** They hold names and ARNs only: the database password reaches the pods
  through ESO, AWS credentials through Pod Identity, and the pull secret is a Kubernetes Secret. Keep `env.sh`
  free of tokens (`ARTIFACTORY_TOKEN` comes from your shell or your CI).
- **Size the PostgreSQL connections.** Each control-plane and polling-agent pod has a connection pool of 100
  (`PostgreSQL__MaxPoolSize`): at 50 pods per partition, the `max_connections` of RDS (derived from the
  instance class) is the limit, not the cluster. See README, "Known limits", for the replication slots.
- **RDS password rotation.** RDS rotates the master password it manages; ESO refreshes the Secret within the
  hour but the pods read it at startup: `kubectl rollout restart` the control plane and the compute plane.
- **Isolate the nodes.** Control plane and ingress on `core`, compute on tainted `workers` (spot, never
  consolidated while a task runs), Valkey on `storage`. A customer partition adds its `nodeSelector` and
  `tolerations` like `partitionCommon` does.
- **`requests == limits` for the compute plane.** The pods are Guaranteed: a dedicated CPU share, evicted last,
  and sized exactly by Karpenter, which picks instances from the requests.
- **Least privilege.** The IAM role of the control plane and the polling agents grants only the S3 and SQS
  calls the Core adaptors make. Keep one role per component when a customer splits them.
- **Seq and Grafana without authentication** are the chart defaults for a demo. Give Seq an admin password
  hash, and put the ingress behind an internal NLB (`armonik-hardening.yaml`).
- **Keep Prometheus data.** It has no volume by default: set `prometheusSpec.storageSpec` (commented in
  `armonik-operators.yaml`).
- **Uninstalling is not symmetric.** CRDs of the operators outlive their release by design: see
  `ArmoniK.Infra/charts/uninstall.md`.

## Removal

In reverse order, waiting for the NLB to disappear after `armonik`, and for the Karpenter nodes after deleting
the NodePools, before removing their controllers (`make charts-destroy` scripts the same sequence):

```sh
helm uninstall armonik -n "$ARMONIK_NS" --wait
kubectl get svc -A | grep LoadBalancer          # wait until empty
helm uninstall aws-secret-store -n "$OPERATORS_NS"
helm uninstall armonik-operators -n "$OPERATORS_NS"
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh             # wait until empty
helm uninstall karpenter-nodes karpenter -n kube-system
```

Then `make delete` (or `terraform destroy`) removes the infrastructure. Skipping the waits leaves an NLB, its
security groups, or EC2 nodes behind, and `terraform destroy` then fails on the VPC.

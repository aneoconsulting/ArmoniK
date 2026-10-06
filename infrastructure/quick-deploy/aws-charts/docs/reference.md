# Reference

Details behind the commands of the [README](../README.md).

## Inputs of helmfile

helmfile renders `values/*.gotmpl` from two layers of environment values: the Terraform outputs
(`generated/armonik-output.json`, written in README step 3), then `values/settings.yaml`. Without our Terraform,
write that JSON by hand with the same keys.

| Terraform output | Used by | Without our Terraform |
|---|---|---|
| `eks.{name,region,vpc_id}` | Karpenter, AWS LB Controller, secret store, ArmoniK | Your EKS cluster and its VPC |
| `namespaces.*` | operators, armonik, armonik-gateway | See the note below |
| `service_accounts.*` | armonik | See the note below |
| `karpenter.{node_role,queue_name,discovery_tag}` | karpenter, karpenter-nodes | Node role, interruption queue, `karpenter.sh/discovery` tag of the subnets and node security group |
| `postgresql.{host,port,database,secret_arn}` | armonik | A PostgreSQL with logical replication, and a Secrets Manager secret `{"username","password"}` |
| `queue.prefix` | armonik | Any prefix; the IAM policy must cover `<prefix>*` |
| `object_storage.bucket` | armonik | Any bucket |
| `registry.{host,upstreams.*}` | every release (unless `registries` in `settings.yaml`) | Your registry, one prefix per upstream |

`values/settings.yaml` holds the rest: chart versions, `registries` and `charts` (Artifactory), `registryAuth`,
`hardening` with `tlsDnsNames`, `grafanaUrl`, and `armonikChartsDir` (a local ArmoniK.Infra checkout instead of
the published charts).

Namespaces and service accounts are not free to choose: EKS Pod Identity binds them to IAM roles by namespace
and name (`terraform/identities.tf`), as well as `external-secrets`, `karpenter` and
`aws-load-balancer-controller`. Renaming one leaves its pod without AWS credentials.

## Versions

| What | Where | Now |
|---|---|---|
| Charts (`helm --version`) | `values/settings.yaml`: `versions.cilium`, `.karpenter`, `.awsLoadBalancerController`, `.envoyGateway`, `.armonik` | 1.20.2, 1.14.1, 3.5.0, 1.9.2, `0.16.1-SNAPSHOT.4.sha.d640d96c` |
| ArmoniK images (Core, GUI) | `values/armonik.yaml.gotmpl`: `global.armonik.versions.core`, `.gui` (empty: the chart's `appVersion`) | Core `0.42.0-refactorrenamepostgresqladapto.26.sha.4f4d363d`, GUI `0.16.0` |
| Envoy Gateway and Envoy images | `values/envoy-gateway.yaml.gotmpl`: `global.images.*.image` | gateway `v1.9.2`, envoy `distroless-v1.39.1` |
| Other images (Cilium, Hubble, Karpenter, operators, Seq, fluent-bit...) | Tag from their chart, only the registry is overridden | follow the chart versions |
| Local charts | `charts/*/Chart.yaml` `version` | 0.1.0 |
| Node AMI | `charts/karpenter-nodes/values.yaml`: `nodeClass.amiAlias` | `al2023@latest` |
| Kubernetes | `parameters.tfvars`: `eks.kubernetes_version` | 1.35 |
| RDS PostgreSQL | `parameters.tfvars`: `rds.engine_version` (default in `terraform/variables.tf`) | 18 |
| Terraform, AWS provider, modules | `terraform/versions.tf`, `version` of each `module` | provider `>= 6.59, < 7.0` |

`versions.armonik` is shared by `armonik` and `armonik-operators`. ArmoniK.Infra CI publishes every branch to Docker
Hub (`dockerhubaneo/armonik`), `main` as `<version>-SNAPSHOT.<n>.sha.<commit>`; the keys of `values/armonik.yaml.gotmpl`
(`dependencies.externalPostgresql` among them) follow `main`. Bumping the chart keeps the Core and GUI pins: change
them together when the chart needs a newer Core.

## Artifactory

One Docker remote repository per upstream (path-based access), three Helm OCI remotes for the charts, and one
classic Helm remote for the AWS Load Balancer Controller chart. Their prefixes go in `values/settings.yaml`:

| Remote | Upstream | Used for |
|---|---|---|
| `registries.dockerHub` | `registry-1.docker.io` | ArmoniK images, Seq, fluent-bit, busybox, Envoy Gateway and Envoy |
| `registries.ghcr` | `ghcr.io` | External Secrets, KEDA, kube-webhook-certgen, configmap-reload |
| `registries.quay` | `quay.io` | cert-manager, Prometheus and its operator, node-exporter, Cilium and Hubble |
| `registries.k8s` | `registry.k8s.io` | kube-state-metrics |
| `registries.ecrPublic` | `public.ecr.aws` | Karpenter, AWS Load Balancer Controller |
| `charts.dockerHub` | `registry-1.docker.io` (Helm OCI) | `armonik`, `armonik-operators`, `gateway-helm` (Envoy Gateway) |
| `charts.ecrPublic` | `public.ecr.aws` (Helm OCI) | `karpenter` |
| `charts.quay` | `quay.io` (Helm OCI) | `cilium` |
| `charts.eksUrl` | `https://aws.github.io/eks-charts` (Helm) | `aws-load-balancer-controller`, read at `https://<host>/artifactory/api/helm/<key>` |

Air-gapped: copy the charts into a local repository, keeping the paths the commands expect, and mirror the
images `helmfile template` lists under the `registries` paths:

```sh
helm pull oci://registry-1.docker.io/dockerhubaneo/armonik --version <versions.armonik>
helm push armonik-<versions.armonik>.tgz "oci://$ARTIFACTORY/helm-local/dockerhubaneo"   # charts.dockerHub: $ARTIFACTORY/helm-local
```

Instead of a pull Secret per namespace, the nodes can hold the credentials (`nodeClass.userData` in
`charts/karpenter-nodes/values.yaml`).

## Running from AWX

The commands of the README run as they are in a shell or a CI job. In AWX (Ansible Automation Platform) the
simplest is a playbook that runs the same commands (`ansible.builtin.command`), helmfile included; with the
Ansible modules instead, not provided here:

| README step | Ansible |
|---|---|
| Terraform init / apply | `community.general.terraform` |
| `terraform output` + `helmfile apply` | `terraform output -json` read into a fact, values files as Jinja2 templates (`template`) |
| `helm registry login`, the releases of `helmfile.yaml.gotmpl` | `kubernetes.core.helm_registry_auth`, `kubernetes.core.helm` (`wait: true`, same order) |
| Registry tokens (Docker Hub, GitHub, Artifactory) | AWX credentials, injected as environment variables |

The jobs run in an execution environment image: it must contain `terraform`, `helm`, `helmfile` (with helm-diff), `aws`, `kubectl` and `jq`, and
the `kubernetes.core` and `community.general` collections. Nothing is installed on the AWX hosts.

## Ingress: Envoy Gateway

The chart `armonik-ingress` always renders its nginx: `values/armonik.yaml.gotmpl` sets it to 0 replicas and a
ClusterIP Service, and Envoy Gateway is the only entry point. `charts/armonik-gateway` holds the NLB settings
(`EnvoyProxy`), the `Gateway` and the routes: a `GRPCRoute` for the ArmoniK API (Envoy talks HTTP/2 to the
control plane), an `HTTPRoute` for the GUI, and long stream timeouts (gRPC streams last as long as a task).
The chart's own Gateway API objects are not used: it only renders an `HTTPRoute`, which breaks gRPC.

What nginx did and Envoy does not:

| nginx | Now |
|---|---|
| `/seq/` with its HTML rewritten | Seq on its own port, 8080 |
| `/grafana/` proxy to `grafana_url` | Users reach the customer Grafana directly |
| GUI language from `Accept-Language` | Redirect to `/admin/en/` |
| `/static/` (environment banner of the GUI) | Not served |
| mTLS, client certificate passed to Core | Not configured; Envoy supports it (`ClientTrafficPolicy` `tls.clientValidation`) |

Cilium is chained on the VPC CNI (the `vpc-cni` addon stays), so its own Gateway API is not used: it needs
kube-proxy replacement.

## Custom choices (`values/armonik.yaml.gotmpl`)

| Choice | Notes |
|---|---|
| RDS PostgreSQL (`dependencies.externalPostgresql`) | Only table backend, `mongodb` off. Logical replication required. Password from Secrets Manager through External Secrets. |
| S3 (`dependencies.s3`, `redis.enabled: false`) | Bucket from Terraform, SSE-KMS. No credentials: Pod Identity of the control and compute planes. |
| SQS (`dependencies.sqs`) | Core creates its queues under the prefix. |
| Cilium + Hubble (`values/cilium.yaml.gotmpl`) | Enforce the NetworkPolicies (`hardening` in `settings.yaml`) and show the flows. New Karpenter nodes wait for the agent (startup taint). |
| Own Grafana (`dependencies.grafana.enabled: false`) | See [grafana-dashboards.md](grafana-dashboards.md). |
| Private registry | Explicit `registry`/`repository` per image: `global.imageRegistry` is not honoured by every dependency. |

## Advice

- **Pin everything**: chart versions, `global.armonik.versions.core` and `.gui`, mirrored images.
- **No secrets in values files**: database password through ESO, AWS through Pod Identity, pull secret as a
  Kubernetes Secret.
- **Isolate the nodes**: control plane on `core`, compute on tainted `workers` (spot, a running task is never
  consolidated). The worker uses `requests == limits`, the agent the chart defaults.
- **Seq has no authentication** by default (see `values/armonik-hardening.yaml.gotmpl`). `hardening: true` in
  `values/settings.yaml` makes the NLB internal and enables TLS.
- **Prometheus has no volume** by default: set `prometheusSpec.storageSpec` in `values/armonik-operators.yaml.gotmpl`.
- **CRDs outlive their release** by design: see `ArmoniK.Infra/charts/uninstall.md`.

## Known limits

- **RDS password rotation** (`rds.password_rotation_days`, 365): ESO refreshes the Secret within the hour, but
  the pods read it at startup, so `kubectl rollout restart` the control and compute planes.
- **PostgreSQL connections**: each control-plane and polling-agent pod has a pool of 100
  (`PostgreSQL__MaxPoolSize`). Size RDS `max_connections` against the maximum number of pods.
- **Replication slots**: up to two per control-plane pod; `rds.max_replication_slots` (20) covers ~10 replicas.
- **AWS Load Balancer Controller chart**: HTTP repository only, so not pulled through the ECR cache (its image is).

## Running a test from inside the cluster

The same htcmock client as the README (step 4), run as a pod and reaching the control plane through its Service:

```sh
CORE=$(helm get values armonik -n armonik -o json | jq -r .global.armonik.versions.core)
REG=$(jq -r .registry.upstreams.dockerHub generated/armonik-output.json)
kubectl run htcmock-client -n armonik --rm -i --restart=Never \
  --image="$REG/dockerhubaneo/armonik_core_htcmock_test_client:$CORE" \
  --env=HtcMock__NTasks=2000 --env=HtcMock__TotalCalculationTime=02:00:00 \
  --env=HtcMock__DataSize=1 --env=HtcMock__MemorySize=1 --env=HtcMock__EnableFastCompute=false \
  --env=HtcMock__SubTasksLevels=1 --env=HtcMock__Partition=htcmock \
  --env=GrpcClient__Endpoint=http://armonik-control-plane:5001
```

KEDA scales the `htcmock` partition up (`kubectl get pods -n armonik -l armonik.fr/partition=htcmock -w`),
Karpenter adds worker nodes (`kubectl get nodeclaims -w`), and both scale back down once the queue is empty.

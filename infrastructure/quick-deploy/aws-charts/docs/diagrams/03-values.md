# 3. Values files: what feeds which release

One values file per release, from `docs/examples/values/`. Each is a static file in which only a few keys are
injected: the infrastructure facts from the Terraform outputs, and the environment choices from CI variables
(see [01-pipeline.md](01-pipeline.md#terraform-output-to-values)).

## Sources, files, releases

```mermaid
flowchart LR
    classDef tf fill:#e8f0fe,stroke:#4a6fa5,color:#111
    classDef env fill:#fff4d6,stroke:#c79a1b,color:#111
    classDef file fill:#ffffff,stroke:#333,color:#111
    classDef opt fill:#f5f5f5,stroke:#999,stroke-dasharray:4 3,color:#555
    classDef rel fill:#e6f4e6,stroke:#2e7d32,stroke-width:2px,color:#111

    subgraph SRC["Where the injected keys come from"]
        TO["Terraform outputs<br/>eks, namespaces, service_accounts,<br/>karpenter, postgresql, queue, object_storage"]:::tf
        EV["CI variables<br/>REG_*, CHARTS_*, chart versions,<br/>GRAFANA_URL"]:::env
    end

    subgraph FILES["Values files (static, versioned)"]
        F1["karpenter.yaml"]:::file
        F2["karpenter-nodes.yaml"]:::file
        F3["aws-load-balancer-controller.yaml"]:::file
        F4["armonik-operators.yaml"]:::file
        F5["aws-secret-store.yaml"]:::file
        F6["armonik.yaml (base)"]:::file
        F7["armonik-registry-auth.yaml"]:::opt
        F8["armonik-hardening.yaml"]:::opt
        F9["local overrides<br/>partitions, resources..."]:::opt
        F0["cilium.yaml"]:::opt
    end

    subgraph REL["Releases"]
        R1["karpenter"]:::rel
        R2["karpenter-nodes"]:::rel
        R3["aws-load-balancer-controller"]:::rel
        R4["armonik-operators"]:::rel
        R5["aws-secret-store"]:::rel
        R6["armonik"]:::rel
        R0["cilium"]:::opt
    end

    TO -->|"cluster name, queue"| F1
    TO -->|"node role, discovery tag"| F2
    TO -->|"cluster name, region, VPC id"| F3
    TO -->|"region"| F5
    TO -->|"namespaces, service accounts, RDS, SQS,<br/>S3, region"| F6
    EV -->|"ECR Public prefix"| F1
    EV -->|"ECR Public prefix"| F3
    EV -->|"GHCR, Quay, Docker Hub prefixes"| F4
    EV -->|"Docker Hub, GHCR, ECR Public prefixes,<br/>GRAFANA_URL"| F6
    EV -->|"Quay prefix"| F0

    F1 --> R1
    F2 --> R2
    F3 --> R3
    F4 --> R4
    F5 --> R5
    F6 -->|"-f 1"| R6
    F7 -->|"-f 2, optional"| R6
    F8 -->|"-f 3, optional"| R6
    F9 -->|"-f last, optional"| R6
    F0 --> R0
```

The `armonik` release takes up to four `-f`, merged in order: later files win, maps merge key by key, and a list
replaces the one before. A layer therefore only holds what changes. In the CI job a generated overlay (variant A or B
of the pipeline) is simply another `-f`.

## What each file contains

| Values file | Static content (versioned) | Injected |
|---|---|---|
| `karpenter.yaml` | controller resources, `nodeSelector` on the `system` node group | `settings.clusterName`, `settings.interruptionQueue`, `controller.image.repository` |
| `karpenter-nodes.yaml` | nothing by default, the defaults are in `charts/karpenter-nodes/values.yaml` | `nodeRole`, `discoveryTag` |
| `aws-load-balancer-controller.yaml` | `keepTLSSecret`, service account name | `clusterName`, `region`, `vpcId`, `image.repository` |
| `armonik-operators.yaml` | which operators are off, per-subchart resources and settings | `OPERATORS_NS`, every image registry (about 17) |
| `aws-secret-store.yaml` | store name `aws-secrets-manager` | `region` |
| `armonik.yaml` | operators `available`, partitions, `partitionCommon` (node pool, resources, `hpa.maxReplicaCount`), NLB annotations, which dependencies are on | namespaces, service accounts, `externalPostgresql.*`, `sqs.*`, `s3.*`, `grafana_url`, every image registry (about 18) |
| `armonik-registry-auth.yaml` | pull secret name per chart family | `ARMONIK_NS` (in its header only) |
| `armonik-hardening.yaml` | internal NLB, `tls`, `mtls`, `networkPolicy.enabled` | none (`extraDnsNames` is a per-environment choice) |
| `cilium.yaml` | chaining mode and routing | Quay prefix |

## Local charts

Two of the six releases are charts of this repository, with their own defaults.

```mermaid
flowchart TD
    classDef chart fill:#dce8ff,stroke:#2f5597,stroke-width:3px,color:#111
    classDef res fill:#e6f4e6,stroke:#2e7d32,color:#111
    classDef lever fill:#fff4d6,stroke:#c79a1b,color:#111

    KN["charts/karpenter-nodes<br/>release karpenter-nodes, -n kube-system"]:::chart
    NC["EC2NodeClass default<br/>AL2023, 50 GiB gp3 encrypted, IMDS hop limit 1,<br/>userData (inotify), subnets + SGs by discovery tag"]:::res
    NPC["NodePool core<br/>on-demand, c m r gen 5+, cpu limit 64<br/>WhenEmptyOrUnderutilized after 5m"]:::res
    NPW["NodePool workers<br/>spot then on-demand, c m, tainted, cpu limit 1000<br/>WhenEmpty after 1m"]:::res
    NPS["NodePool storage<br/>on-demand r, tainted, cpu limit 16<br/>WhenEmpty after 5m (Valkey)"]:::res
    SC["StorageClass gp3 (default)<br/>ebs.csi.aws.com, encrypted, WaitForFirstConsumer"]:::res
    KNL["levers: nodeRole, discoveryTag, poolLabel,<br/>nodeClass.amiAlias / volumeSize / userData,<br/>nodePools.NAME.* (capacityTypes, instanceCategories,<br/>minGeneration, taint, limits, disruption),<br/>storageClass.create / name"]:::lever
    KN --> NC
    KN --> NPC
    KN --> NPW
    KN --> NPS
    KN --> SC
    KN -.- KNL

    SS["charts/aws-secret-store<br/>release aws-secret-store, -n OPERATORS_NS"]:::chart
    CSS["ClusterSecretStore aws-secrets-manager<br/>provider aws, SecretsManager, no auth block:<br/>ESO uses its own Pod Identity"]:::res
    SSL["levers: name, region"]:::lever
    SS --> CSS
    SS -.- SSL
```

The `workers` pod placement is the contract between the two charts: `armonik.yaml` selects and tolerates
`armonik.aneo.fr/node-pool: workers` (compute plane) and `storage` (Valkey), which `poolLabel` and `taint` create.

## Choices and where they are set

| Choice | Keys in `armonik.yaml` | Related |
|---|---|---|
| Table storage | `dependencies.externalPostgresql.enabled` (RDS), or `dependencies.mongodb.enabled` | exclusive; MongoDB also needs `operators.mongodbOperator` |
| Queue | `dependencies.sqs.enabled`, `activemq.enabled`, `rabbitmq.enabled` | one at a time; the SQS IAM policy covers `<prefix>*` |
| Object storage | `dependencies.redis.enabled` (Valkey), or `dependencies.s3.enabled` | Valkey is in memory and lost with the pod |
| Autoscaling | `compute-plane.partitionCommon.hpa.maxReplicaCount`, per-partition `hpa` | KEDA, from the operators release |
| Compute sizing | `partitionCommon.agent/worker.resources`, `partitions.NAME.worker.*` | `requests == limits` gives Guaranteed pods and exact Karpenter sizing |
| Node placement | `nodeSelector`, `tolerations` on `partitionCommon` and `redis` | pools of `karpenter-nodes` |
| Ingress | `ingress.service.annotations`, `ingress.tls`, `ingress.mtls` | internal vs internet-facing in `armonik-hardening.yaml` |
| Grafana | `dependencies.grafana.enabled`, `ingress.grafana_url` | disabled: no datasource or dashboard ConfigMaps rendered |
| Prometheus | `global.armonik.monitoring.prometheusUrl` | the operators' stack, or the customer's |
| Image tags | `global.armonik.versions.core`, `.gui` | empty follows the chart's `appVersion` |
| NetworkPolicies | `networkPolicy.enabled` | needs a CNI that enforces them, or `cilium` |

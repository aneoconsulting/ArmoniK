# 1. Deployment pipeline: Terraform outputs to helm releases

What a CI/CD job (Bamboo) does, from the Terraform outputs to the six `helm upgrade --install` of
[helm-cli.md](../helm-cli.md). Only `helm`, `kubectl`, `aws` and Terraform are involved: no helmfile.

## The pipeline

```mermaid
flowchart TD
    classDef tf fill:#e8f0fe,stroke:#4a6fa5,color:#1a1a1a
    classDef gen fill:#fff4d6,stroke:#c79a1b,color:#1a1a1a
    classDef step fill:#eef7ee,stroke:#4c8f4c,color:#1a1a1a
    classDef rel fill:#ffffff,stroke:#333,stroke-width:2px,color:#1a1a1a
    classDef opt fill:#f5f5f5,stroke:#999,stroke-dasharray:4 3,color:#555

    subgraph S1["Stage 1 - Infrastructure (Terraform, make init apply)"]
        APPLY["terraform apply<br/>VPC, EKS, RDS, S3, Karpenter IAM + queue,<br/>Pod Identity roles, ECR cache"]:::tf
        OUT["terraform output -json<br/>eks, namespaces, service_accounts, karpenter,<br/>postgresql, queue, object_storage, registry"]:::tf
        APPLY --> OUT
    end

    subgraph S2["Stage 2 - Generate the values (the awk step, see variants below)"]
        GEN["outputs to values<br/>one set of values per release"]:::gen
        ENVC["environment choices<br/>registries, chart versions, Grafana URL<br/>(CI variables)"]:::gen
        STATIC["static values files<br/>docs/examples/values/*.yaml"]:::gen
        VALS["generated/values/*.yaml"]:::gen
        OUT --> GEN --> VALS
        ENVC --> VALS
        STATIC --> VALS
    end

    subgraph S3["Stage 3 - Access"]
        KUBE["aws eks update-kubeconfig<br/>(cluster name + region from eks.*)"]:::step
        LOGIN["helm registry login<br/>ECR: aws ecr get-login-password<br/>Artifactory: user + token"]:::step
        PREP["optional: pull secret per namespace<br/>(Artifactory with authentication)"]:::opt
    end
    OUT --> KUBE
    ENVC --> LOGIN
    LOGIN --> PREP

    subgraph S4["Stage 4 - Check, nothing reaches the cluster"]
        TPL["helm template armonik + armonik-operators<br/>scripts/check-images.sh REGISTRY_HOST"]:::step
    end
    VALS --> TPL
    KUBE --> TPL
    LOGIN --> TPL

    subgraph S5["Stage 5 - Install, in this order, each one --wait"]
        R0["0 cilium (optional)<br/>NetworkPolicies enforcement<br/>-n kube-system"]:::opt
        R1["1 karpenter<br/>oci ECR Public, -n kube-system<br/>starts and stops EC2 nodes"]:::rel
        R2["2 karpenter-nodes (local chart)<br/>-n kube-system<br/>EC2NodeClass, 3 NodePools, gp3 StorageClass"]:::rel
        R3["3 aws-load-balancer-controller<br/>HTTP repo eks-charts, -n kube-system<br/>Service LoadBalancer to NLB"]:::rel
        R4["4 armonik-operators<br/>oci Docker Hub, -n OPERATORS_NS<br/>ESO, KEDA, cert-manager, Prometheus<br/>--timeout 10m"]:::rel
        R5["5 aws-secret-store (local chart)<br/>-n OPERATORS_NS<br/>ClusterSecretStore on Secrets Manager"]:::rel
        R6["6 armonik<br/>oci Docker Hub, -n ARMONIK_NS<br/>control plane, compute plane, ingress, Valkey, Seq...<br/>--timeout 15m, no --wait-for-jobs"]:::rel
        R0 -.-> R1
        R1 -->|CRDs| R2
        R2 -->|nodes to run on| R3
        R3 --> R4
        R4 -->|ESO CRDs| R5
        R5 --> R6
        R3 -.->|webhook ready| R6
        R4 -.->|operators CRDs| R6
    end
    TPL --> R0
    TPL --> R1
    VALS -.->|"-f values"| S5

    R6 --> NLB["kubectl get svc armonik-ingress<br/>NLB hostname, ArmoniK CLI endpoint"]:::step
```

Each release takes its own values file, see [03-values.md](03-values.md). `--install` makes every command safe to
rerun, and `--reuse-values` is never used: the next upgrade would replay old values and ignore the chart's new
defaults. Removal is the same list in reverse, waiting for the NLB after `armonik` and for the Karpenter nodes
after the NodePools.

## Terraform output to values

Source: `terraform/outputs.tf`, and `docs/examples/env.sh` for the variable names. The values files are static
templates: these are the only keys that depend on the infrastructure.

| Terraform output | `env.sh` variable | Values file | Key |
|---|---|---|---|
| `eks.name` | `CLUSTER_NAME` | `karpenter.yaml` | `settings.clusterName` |
| | | `aws-load-balancer-controller.yaml` | `clusterName` |
| | | (also) `aws eks update-kubeconfig --name` | |
| `eks.region` | `AWS_REGION` | `aws-load-balancer-controller.yaml` | `region` |
| | | `aws-secret-store.yaml` | `region` |
| | | `armonik.yaml` | `dependencies.sqs.region`, `dependencies.s3.region` |
| `eks.vpc_id` | `VPC_ID` | `aws-load-balancer-controller.yaml` | `vpcId` |
| `namespaces.operators` | `OPERATORS_NS` | `helm -n` of releases 4 and 5 | |
| | | `armonik.yaml` | `global.armonik.operators.<op>.namespace`, `global.armonik.monitoring.prometheusUrl` |
| `namespaces.armonik` | `ARMONIK_NS` | `helm -n` of release 6, `armonik-registry-auth` secret | |
| `service_accounts.control_plane` | `SA_CONTROL_PLANE` | `armonik.yaml` | `control-plane.serviceAccount.name` |
| `service_accounts.compute_plane` | `SA_COMPUTE_PLANE` | `armonik.yaml` | `compute-plane.serviceAccount.name` |
| `karpenter.queue_name` | `KARPENTER_QUEUE` | `karpenter.yaml` | `settings.interruptionQueue` |
| `karpenter.node_role` | `KARPENTER_NODE_ROLE` | `karpenter-nodes.yaml` | `nodeRole` |
| `karpenter.discovery_tag` | `KARPENTER_DISCOVERY_TAG` | `karpenter-nodes.yaml` | `discoveryTag` |
| `postgresql.host`, `.port`, `.database` | `PG_HOST`, `PG_PORT`, `PG_DATABASE` | `armonik.yaml` | `dependencies.externalPostgresql.{host,port,database}` |
| `postgresql.secret_arn` | `PG_SECRET_ARN` | `armonik.yaml` | `dependencies.externalPostgresql.credentials.secret` |
| `queue.prefix` | `SQS_PREFIX` | `armonik.yaml` | `dependencies.sqs.prefix` |
| `object_storage.bucket` | `S3_BUCKET` | `armonik.yaml` | `dependencies.s3.bucketName` (S3 variant) |
| `registry.upstreams.*` | `REG_DOCKERHUB`, `REG_GHCR`, `REG_QUAY`, `REG_K8S`, `REG_ECR_PUBLIC` | all files | every `image.registry` / `image.repository` |
| `registry.host` | none: `env.sh` does not read it, helm-cli.md derives `REGISTRY_HOST=${REG_DOCKERHUB%%/*}` | `helm registry login`, `check-images.sh` | |

Not outputs, but injected the same way: `CHARTS_DOCKERHUB`, `CHARTS_ECR_PUBLIC`, `EKS_CHARTS_URL` (where the charts are
pulled from), the chart versions (`--version`, never in a values file) and `GRAFANA_URL` (`ingress.grafana_url`).
`eks.endpoint` and `kubeconfig_command` are not read by any values file.

Names that are **not free**: the service accounts, `external-secrets`, `karpenter` and `aws-load-balancer-controller`
are bound to IAM roles by EKS Pod Identity, by namespace and name (`terraform/identities.tf`). A pipeline that
renames one of them leaves the pod without AWS credentials.

## Variants of the "outputs to values" step

The format is not decided. The values to produce split in two kinds, which do not have the same best source:

- **Infrastructure facts** (names, ARNs, hosts, prefixes): about 20 keys in total, all in the table above.
  They come from Terraform.
- **Environment choices** (registry prefixes, chart versions, Grafana URL): they do not come from Terraform when the
  registry is the customer's Artifactory. They are CI variables. The registry prefixes are the awkward part: about
  35 occurrences across `armonik.yaml` and `armonik-operators.yaml`, because `global.imageRegistry` is not honoured
  by every dependency (Valkey and Seq among them).

```mermaid
flowchart LR
    classDef tf fill:#e8f0fe,stroke:#4a6fa5,color:#1a1a1a
    classDef gen fill:#fff4d6,stroke:#c79a1b,color:#1a1a1a
    classDef out fill:#eef7ee,stroke:#4c8f4c,color:#1a1a1a
    classDef best fill:#eef7ee,stroke:#2e7d32,stroke-width:3px,color:#1a1a1a

    OUT["terraform output"]:::tf

    OUT -->|"A: Terraform builds the YAML"| A1["outputs.tf: one output per release<br/>value = yamlencode(...)"]:::best
    A1 -->|"terraform output -raw"| A2["generated/release.yaml"]:::gen

    OUT -->|"B: small overlay"| B1["jq or awk: flatten the outputs<br/>to a YAML overlay of the ~20 keys"]:::gen
    B1 --> B2["generated/release.overlay.yaml"]:::gen

    OUT -->|"C: variables then render"| C1["awk: KEY=VALUE lines<br/>(replaces jq in env.sh)"]:::gen
    C1 --> C2["envsubst on the values<br/>templates with placeholders"]:::gen
    C2 --> C3["generated/values/*.yaml"]:::gen

    A2 --> HELM
    B2 --> HELM
    C3 --> HELM
    HELM["helm upgrade --install<br/>-f static.yaml -f generated.yaml"]:::out
```

| | A: Terraform `yamlencode` | B: static files + generated overlay | C: awk variables + envsubst (current flow) |
|---|---|---|---|
| awk needed | no | optional (jq does it better) | yes, replaces the `jq` calls of `env.sh` |
| Static values files | valid YAML, no placeholder | valid YAML, no placeholder | templates, invalid until rendered |
| Infra values can drift from the resources | no, built in the same Terraform run | possible | possible |
| Registry prefixes | CI overlay, or set in Terraform | CI overlay | `${REG_*}` placeholders, as today |
| Change to the pipeline when an output is added | an `outputs.tf` edit | edit the flatten step | edit `env.sh` and the `ENVSUBST_VARS` list |
| Risk | Terraform owns Helm key names | awk or jq on nested JSON | an unfilled `${VAR}` reaches helm (`grep -l '\${'` guards it) |

Recommendation: **A for the infrastructure facts, plus a small CI overlay for the environment choices** (registries,
versions, Grafana URL), layered with `-f`, the generated file after the static one. If the customer imposes awk, B is
the least fragile: it keeps the static files valid on their own, and awk only produces the short overlay. C is what
`docs/examples` does today and works as is, with `awk` in place of `jq`.

# 2. From Terraform to the helm releases

Terraform creates the AWS side and prints its outputs. A CI step turns them into values files, and `helm` installs
the releases in order.

```mermaid
flowchart LR
    classDef tf fill:#e8f0fe,stroke:#4a6fa5,color:#111
    classDef gen fill:#fff4d6,stroke:#c79a1b,color:#111
    classDef rel fill:#e6f4e6,stroke:#2e7d32,stroke-width:2px,color:#111

    subgraph TF["Terraform"]
        direction TB
        INFRA["EKS, VPC, RDS, S3, IAM + Pod Identity,<br/>Karpenter interruption queue"]:::tf
        OUT["outputs<br/>eks, namespaces, service_accounts, karpenter,<br/>postgresql, object_storage, queue (prefix only)"]:::tf
        INFRA --> OUT
    end

    subgraph CI["CI job (Bamboo)"]
        direction TB
        STATIC["static values files<br/>one per release"]:::gen
        ENV["environment choices<br/>registries, chart versions"]:::gen
        GEN["generate the values<br/>(outputs to YAML)"]:::gen
        VALS["values files, ready"]:::gen
        STATIC --> VALS
        ENV --> VALS
        GEN --> VALS
    end
    OUT --> GEN

    subgraph HELM["helm upgrade --install, in this order"]
        direction TB
        R0["0 cilium (+ Hubble)"]:::rel
        R1["1 karpenter"]:::rel
        R2["2 karpenter-nodes"]:::rel
        R3["3 aws-load-balancer-controller"]:::rel
        R4["4 armonik-operators"]:::rel
        R5["5 aws-secret-store"]:::rel
        R6["6 eg (Envoy Gateway)"]:::rel
        R7["7 armonik"]:::rel
        R8["8 armonik-gateway"]:::rel
        R0 --> R1 --> R2 --> R3 --> R4 --> R5 --> R6 --> R7 --> R8
    end
    VALS -->|"one -f per release"| HELM
```

## Which output feeds which release

| Terraform output | Feeds | Key |
|---|---|---|
| `eks` (name, region, vpc_id) | 1 karpenter, 3 load balancer controller, 5 secret store | cluster name, region, VPC id |
| `karpenter` (node role, queue, discovery tag) | 1 karpenter, 2 karpenter-nodes | `interruptionQueue`, `nodeRole`, `discoveryTag` |
| `namespaces`, `service_accounts` | 4, 5, 7, 8 | `-n`, and `serviceAccount.name` of the control plane and compute plane |
| `postgresql` (host, port, database, secret ARN) | 7 armonik | `dependencies.externalPostgresql.*` |
| `queue` (prefix) | 7 armonik | `dependencies.sqs.prefix` (Core creates the queues itself) |
| `object_storage` (bucket) | 7 armonik | `dependencies.s3.bucketName` |

Not Terraform outputs: the registry prefixes and the chart versions are CI variables. Everything is read from `values/env.sh` and `terraform/outputs.tf`.

SQS: Terraform creates no ArmoniK queue. It only creates the queue Karpenter reads its spot interruptions from, and
grants the Pod Identity role of the control plane and compute plane the right to create and use queues under the
prefix. The queues appear when Core starts.

## The "generate the values" step

The format is not decided, and it does not need to be: the step only has to produce the ~15 keys above.

- **Best: Terraform writes the YAML itself.** One output per release built with `yamlencode(...)`, then
  `terraform output -raw` to a file. No awk, and the values cannot drift from the resources.
- **If awk is imposed:** keep the static files valid on their own and let awk write a short overlay of the keys
  above, passed as the last `-f`. The overlay is small, so it stays readable and easy to review.
- **Today's flow** (`env.sh` + `envsubst`) works as is: awk can replace its `jq` calls.

Registry prefixes are the awkward part, repeated on most images because `global.imageRegistry` is not honoured by every
dependency. They belong in the CI variables, not in Terraform.

## Order and why

Each release needs the previous ones to be ready, hence `--wait`:

1. **Cilium** first, so that no pod starts outside the policies. Karpenter nodes then start tainted until its agent
   is ready.
2. **Karpenter**, then its node pools: without them nothing else can be scheduled.
3. **Load balancer controller**: it must exist before a `Service` of type `LoadBalancer` is created.
4. **Operators**, then the **secret store**: both bring CRDs (External Secrets, KEDA, cert-manager) that the `armonik`
   release uses.
5. **Envoy Gateway**: the controller and the Gateway API CRDs.
6. **armonik**. No `--wait-for-jobs`: the init Jobs delete themselves, and helm would fail on them.
7. **armonik-gateway**, last: its routes point to the Services of `armonik`.

The commands are in the [README](../../README.md#3-helm), step 3.

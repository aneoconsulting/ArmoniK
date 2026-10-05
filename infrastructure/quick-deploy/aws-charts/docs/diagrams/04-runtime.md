# 4. Runtime: what talks to what once deployed

The customer scenario of `docs/examples/values/armonik.yaml`: RDS PostgreSQL for the tasks, Valkey for the objects,
SQS for the queue, the operators' Prometheus, the customer's own Grafana. Dashed grey = off here.

```mermaid
flowchart TD
    classDef ext fill:#ffffff,stroke:#333,color:#111
    classDef k8s fill:#e6f4e6,stroke:#2e7d32,color:#111
    classDef aws fill:#e8f0fe,stroke:#4a6fa5,color:#111
    classDef op fill:#ece6f7,stroke:#7a5cb0,color:#111
    classDef off fill:#f3f3f3,stroke:#9e9e9e,stroke-dasharray:5 4,color:#666

    CLIENT["ArmoniK client / CLI<br/>endpoint http(s)://NLB:5001"]:::ext

    subgraph AWSZ["AWS"]
        NLB["NLB (internet-facing or internal)<br/>created by the AWS Load Balancer Controller<br/>from the ingress Service annotations"]:::aws
        RDS[("RDS PostgreSQL<br/>tasks, results, sessions<br/>logical replication on")]:::aws
        SQS[("SQS<br/>queues named after the prefix,<br/>created by Core")]:::aws
        S3[("S3 bucket<br/>alternative object store")]:::off
        SM["Secrets Manager<br/>RDS master user secret"]:::aws
        EC2["EC2 nodes<br/>started by Karpenter:<br/>core, workers (spot), storage"]:::aws
    end

    subgraph ARMO["Namespace ARMONIK_NS (release armonik)"]
        ING["ingress: nginx + Admin GUI<br/>TLS and mTLS optional"]:::k8s
        CP["control-plane<br/>submitter API, metrics-exporter, init Job<br/>serviceAccount SA_CONTROL_PLANE"]:::k8s
        CPT["compute-plane partitions<br/>polling-agent + worker pods<br/>serviceAccount SA_COMPUTE_PLANE<br/>0 to maxReplicaCount pods"]:::k8s
        VK["Valkey (redis)<br/>objects in memory<br/>on the storage node pool"]:::k8s
        FB["fluent-bit (every node)"]:::k8s
        SEQ["Seq<br/>logs"]:::k8s
        ES["ExternalSecret<br/>PostgreSQL user + password"]:::k8s
        GRAF["customer Grafana<br/>outside the release<br/>reached by ingress.grafana_url"]:::off
    end

    subgraph OPSZ["Namespace OPERATORS_NS (release armonik-operators + aws-secret-store)"]
        ESO["External Secrets Operator<br/>Pod Identity: reads the RDS secret"]:::op
        CSS["ClusterSecretStore<br/>aws-secrets-manager"]:::op
        KEDA["KEDA"]:::op
        PROM["Prometheus (kube-prometheus-stack)"]:::op
        CM["cert-manager"]:::op
    end

    subgraph KSYS["Namespace kube-system"]
        KARP["Karpenter<br/>Pod Identity, EC2 + interruption queue"]:::op
        LBC["AWS Load Balancer Controller<br/>Pod Identity"]:::op
    end

    CLIENT --> NLB --> ING
    ING -->|gRPC| CP
    ING -.->|"/grafana/"| GRAF
    CP -->|"table storage"| RDS
    CP -->|"queue"| SQS
    CP -->|"objects"| VK
    CP -.->|"objects, S3 variant"| S3
    CPT -->|"pull tasks"| SQS
    CPT -->|"results, objects"| VK
    CPT -->|"task state"| RDS

    CSS --> ES
    ES -->|"creates the Secret read by the pods at startup"| CP
    ES --> CPT
    ESO --> CSS
    ESO -->|"Pod Identity"| SM
    RDS -.->|"RDS manages the master secret"| SM

    KEDA -->|"scales on the queue length"| CPT
    PROM -->|"scrapes"| CP
    PROM -->|"scrapes"| CPT
    CM -->|"certificates"| ING

    FB --> SEQ
    CPT -.->|"logs"| FB
    CP -.->|"logs"| FB

    LBC -->|"provisions"| NLB
    KARP -->|"adds nodes for pending pods"| EC2
    EC2 -.->|"host the pods"| CPT
    EC2 -.->|"host the pods"| VK
```

## What to read from it

- **AWS credentials never reach a Secret.** The AWS APIs (S3, SQS, EC2, Secrets Manager, the load balancer API) are
  called with EKS Pod Identity, by namespace and service account name. This is why `SA_CONTROL_PLANE`,
  `SA_COMPUTE_PLANE`, `external-secrets`, `karpenter` and `aws-load-balancer-controller` are contracts with
  Terraform. The one secret is the RDS master password, which stays in Secrets Manager and reaches the pods through
  the External Secrets Operator.
- **Pods read the RDS password at startup.** After a rotation (`rds.password_rotation_days`, 365 by default) ESO
  refreshes the Kubernetes Secret within the hour, but the control plane and compute plane must be restarted.
- **The compute plane starts at zero pods.** KEDA scales a partition on its queue, Karpenter adds `workers` nodes
  for the pending pods, and removes them when empty.
- **Valkey holds every object in memory, with no persistence.** It runs on the tainted `storage` pool, and a restart
  loses the objects. The S3 variant (`redis.enabled: false`, `s3.enabled: true`) keeps them.
- **PostgreSQL connections scale with the pods.** Every control-plane and polling-agent pod has its own pool
  (`PostgreSQL__MaxPoolSize`, 100 by default): at 50 pods per partition, RDS `max_connections` is the limit.

Sources: `docs/helm-cli.md` (customer scenario, advice), `docs/examples/values/armonik.yaml`, `terraform/outputs.tf`,
`README.md` ("Known limits").

# 1. What gets deployed

ArmoniK on an existing Kubernetes cluster (EKS), with Cilium, Karpenter, RDS PostgreSQL, S3 and SQS, and Envoy as the
only ingress. The `armonik` umbrella chart is on top, what it installs below. The numbers are the install order of
the helm releases.

```mermaid
flowchart TD
    classDef umb fill:#dce8ff,stroke:#2f5597,stroke-width:3px,color:#111
    classDef on fill:#e6f4e6,stroke:#2e7d32,stroke-width:2px,color:#111
    classDef plat fill:#ece6f7,stroke:#7a5cb0,color:#111
    classDef aws fill:#e8f0fe,stroke:#4a6fa5,color:#111
    classDef off fill:#f3f3f3,stroke:#9e9e9e,stroke-dasharray:5 4,color:#666

    U["<b>6 armonik</b> (umbrella chart)"]:::umb

    subgraph APP["Installed by the umbrella"]
        direction TB
        CP["control-plane<br/>submitter API"]:::on
        COMP["compute-plane<br/>polling agent + worker per partition<br/>autoscaled by KEDA"]:::on
        ING["ingress: Gateway + HTTPRoute (Envoy)<br/>gateway.enabled, gatewayClassName, tls"]:::on
        subgraph STORE["Storage, one backend per slot"]
            direction LR
            PG["externalPostgresql<br/>tables"]:::on
            S3C["s3<br/>objects"]:::on
            SQSC["sqs<br/>queue"]:::on
        end
        subgraph MON["Monitoring (dependencies)"]
            direction LR
            GR["Grafana"]:::on
            FB["fluent-bit"]:::on
            SEQ["Seq"]:::on
        end
        OFF["Off: mongodb, activemq, rabbitmq, redis (Valkey)<br/>levers: dependencies.NAME.enabled<br/>nginx: not deployed (chart change, see To validate)"]:::off
    end
    U --> CP
    U --> COMP
    U --> ING
    U --> STORE
    U --> MON
    U --- OFF

    subgraph PLAT["Platform, installed before (each release needs the previous ones)"]
        direction TB
        CIL["0 Cilium + Hubble<br/>NetworkPolicies, Hubble flows,<br/>Envoy (case A, see below)"]:::plat
        KAR["1-2 Karpenter + node pools<br/>core (on-demand), workers (spot)"]:::plat
        LBC["3 AWS Load Balancer Controller<br/>Service LoadBalancer to NLB"]:::plat
        OPS["4 armonik-operators<br/>External Secrets, KEDA,<br/>cert-manager, Prometheus"]:::plat
        CSS["5 aws-secret-store<br/>ClusterSecretStore"]:::plat
        CIL --> KAR --> LBC --> OPS --> CSS
    end
    CSS -.->|"needed by"| U

    subgraph AWSZ["AWS"]
        direction LR
        RDS[("RDS PostgreSQL<br/>Terraform")]:::aws
        S3[("S3 bucket<br/>Terraform")]:::aws
        SQS[("SQS queues<br/>created by Core, not Terraform")]:::aws
        SM["Secrets Manager<br/>RDS password"]:::aws
    end
    PG --> RDS
    S3C --> S3
    SQSC --> SQS
    CSS -.-> SM
```

Sources: `ArmoniK.Infra/charts/armonik` and `armonik-operators`, `docs/helm-cli.md`, `docs/examples/values/`.

## Envoy as the only ingress: two ways to run it

Envoy is the only entry point: no nginx. The ArmoniK side is the same in both cases (`ingress.gateway.*` and an
`HTTPRoute` to the control plane and the GUI); only the platform under it differs.

```mermaid
flowchart LR
    classDef n fill:#ece6f7,stroke:#7a5cb0,color:#111
    classDef e fill:#e6f4e6,stroke:#2e7d32,stroke-width:2px,color:#111
    classDef b fill:#fff,stroke:#555,color:#111

    subgraph A["Case A: the Envoy of Cilium"]
        direction LR
        NA["NLB"]:::n --> EA["Envoy<br/>run by Cilium<br/>GatewayClass cilium"]:::e --> BA["control-plane<br/>GUI"]:::b
    end
    subgraph B["Case B: Envoy Gateway"]
        direction LR
        NB["NLB"]:::n --> EB["Envoy proxy pods<br/>run by the Envoy Gateway<br/>controller (one more release)"]:::e --> BB["control-plane<br/>GUI"]:::b
    end
```

| | A. Cilium | B. Envoy Gateway |
|---|---|---|
| Extra release | none, Envoy is part of Cilium | the Envoy Gateway chart, installed after Cilium |
| Prerequisites | `kubeProxyReplacement: true`, Gateway API CRDs installed separately | Gateway API CRDs; no constraint on the CNI |
| Cilium mode | to validate: the Gateway API is not documented with Cilium chained on the VPC CNI | chaining or replacement, both fine |
| NLB annotations | not found in the documentation for the Gateway Service: to validate | on the `EnvoyProxy` resource (`envoyService.annotations`) |
| Upgrades | tied to the Cilium version | independent |

Both cases have a single ingress. A is the smaller platform if it works in the Cilium mode retained; B is the safe
fallback, at the price of one more release. Once the customer has decided, only one of the two stays in the docs.

## The choices

| Choice | What it means | Lever |
|---|---|---|
| **RDS PostgreSQL** | The only table backend. MongoDB and its operator are off; the chart refuses both at once. The password stays in Secrets Manager and reaches the pods through External Secrets. | `dependencies.externalPostgresql.enabled`, `dependencies.mongodb.enabled: false` |
| **S3** | Objects are stored in S3, which survives a restart, unlike Valkey (in memory). No Valkey, so no dedicated `storage` node pool. | `dependencies.s3.enabled`, `dependencies.redis.enabled: false` |
| **SQS** | Core creates its queues under a prefix, at runtime. Terraform only provides the prefix and the IAM policy for it. ActiveMQ and RabbitMQ stay off. | `dependencies.sqs.enabled` and `prefix` |
| **AWS credentials** | None stored: S3, SQS, EC2 and Secrets Manager are reached with EKS Pod Identity, bound to the service accounts by namespace and name. | `serviceAccount.name` of each chart |
| **Karpenter** | Starts and stops nodes after the pending pods. Compute pods run on the `workers` pool (spot first), the rest on `core`. | `karpenter-nodes` values: `nodePools.*` |
| **Cilium + Hubble** | Enforces NetworkPolicies and shows the flows (Hubble). Helm only: Hubble is a set of values of the Cilium chart. Install it first, so that no pod starts uncovered. | `networkPolicy.enabled`, Cilium `hubble.relay.enabled`, `hubble.ui.enabled` |
| **Monitoring** | The chart's own: Prometheus (from the operators, also read by KEDA), Grafana, fluent-bit and Seq. A customer Grafana replaces the chart's with `dependencies.grafana.enabled: false`. | `dependencies.grafana.enabled`, `global.armonik.monitoring.prometheusUrl` |

## To validate

- **The chart still deploys nginx.** In `armonik-ingress`, the nginx Deployment and its Service are rendered whatever
  `gateway.enabled` says, and the default `HTTPRoute` points to that Service. "Envoy only" therefore needs a change in
  `ArmoniK.Infra`: do not render nginx when `httpRoute.enabled`, and route straight to the control plane and the GUI
  (`httpRoute.rules` already accepts any `backendRefs`).
- **What nginx does today and Envoy must take over:** gRPC and HTTP routing to the control plane, the GUI, the
  `/grafana` and `/seq` routes, and TLS and mTLS. TLS termination is a Gateway listener; mTLS depends on the
  implementation chosen.
- **Which Envoy the customer runs.** They already have Cilium and Envoy: find out if it is Cilium's own, a separate
  install, or Envoy Gateway. It decides between A and B.
- **Cilium mode.** Chained on the VPC CNI keeps the `vpc-cni` addon of `terraform/eks.tf`: nodes are `Ready` before
  Cilium, the NLB and Pod Identity are unchanged. Replacing the VPC CNI is heavier (nodes `NotReady` until Cilium is
  up, ENI IPAM, extra IAM rights), and is the case where installing Cilium in the Terraform apply, as the customer
  does, is easier.

# Envoy Gateway entry point

How ArmoniK is exposed through Envoy Gateway instead of the ArmoniK nginx, and how to deploy it in a customer
cluster and VPC (not the ones `terraform/` creates).

Scope of this page: the `eg` and `armonik-gateway` releases, and the parts of `values/armonik.yaml` they depend
on. Everything else follows the [README](../README.md).

## Overview

```
client ──► NLB (5001 / 5000 / 8080, IP targets)          created by the AWS Load Balancer Controller
             │
             ▼
           Envoy pods (envoy-gateway-system, core nodes)   created by the Envoy Gateway controller
             │
             ├─ gRPC armonik.*      ──► armonik-control-plane:5001
             ├─ /, /admin, /admin/  ──► 302 to /admin/en/
             ├─ /admin/*            ──► armonik-ingress-gui:1080
             ├─ /grafana/*          ──► armonik-grafana:80
             └─ :8080, any path     ──► armonik-seq:80
```

| Component | Installed by | Namespace | Role |
|---|---|---|---|
| AWS Load Balancer Controller (LBC) | The customer (already present) | `kube-system` usually | Turns the Envoy Service into an NLB |
| Envoy Gateway controller | Release `eg` (chart `envoyproxy/gateway-helm`, `values/envoy-gateway.yaml`) | `envoy-gateway-system` | Gateway API and Envoy CRDs; deploys and configures Envoy for each Gateway |
| Envoy proxy pods and their Service | The Envoy Gateway controller, from the objects below | `envoy-gateway-system` | Data plane, behind the NLB |
| Gateway, routes, policies | Release `armonik-gateway` (`charts/armonik-gateway`, `values/armonik-gateway.yaml`) | `$ARMONIK_NS` | ArmoniK listeners, routing and timeouts |

Nothing creates the NLB explicitly. The chain is: `EnvoyProxy` (Service settings) → Envoy Gateway creates the
Service → the LBC reads its annotations → NLB.

## The local chart `charts/armonik-gateway`

Every object is named `name` (default `armonik`) and the objects refer to each other by that name.

| File | Object | What it does |
|---|---|---|
| `gatewayclass.yaml` | `GatewayClass` (cluster-scoped) | `controllerName` hands the class to Envoy Gateway; `parametersRef` points to the `EnvoyProxy`, so every Gateway of the class inherits it |
| `envoyproxy.yaml` | `EnvoyProxy` | Envoy Deployment (replicas, resources, `core` nodeSelector, pull secrets) and its Service: `LoadBalancer` with the LBC annotations `aws-load-balancer-type: external`, `nlb-target-type: ip`, `scheme`, plus `loadBalancer.annotations` |
| `gateway.yaml` | `Gateway` | Listeners `grpc` (5001), `http` (5000) and `seq` (8080), the ports nginx used. All are `HTTP`: `grpc` and `http` serve the same routes, since Envoy accepts HTTP/1.1 and h2c on one port |
| `routes.yaml` | `GRPCRoute` + `HTTPRoute`s | API: every `armonik.*` gRPC service to the control plane. A `GRPCRoute`, not an `HTTPRoute`, so Envoy talks HTTP/2 to a backend whose Service does not declare it. GUI under `/admin/`. Seq at the root of its own listener (it cannot live under a prefix without HTML rewriting). Grafana under `/grafana/`, path kept |
| `policies.yaml` | `ClientTrafficPolicy` + `BackendTrafficPolicy` | Envoy cuts idle streams after 5 min and requests after 15 s by default. ArmoniK keeps gRPC streams open for the whole task, so: `streamIdleTimeout: 720h` on the Gateway, and no request or stream duration limit on the API route |
| `certificate.yaml` | cert-manager `Issuer`s + `Certificate`s | Only with `tls.enabled` (not used in this deployment) |
| `values.yaml` | – | Defaults: ports, replicas (2), resources, timeouts, `grafana.enabled`, `loadBalancer`, `tls` |

The Envoy pods run in `envoy-gateway-system`, not in `$ARMONIK_NS`: the controller creates them in its own
namespace. The routes and their backend Services share the Gateway's namespace, so no `ReferenceGrant` is needed.

## What `values/armonik.yaml` does for Envoy

- **nginx is turned off, not removed.** The `armonik-ingress` subchart also carries the admin GUI, so
  `ingress.enabled: false` is not an option. Instead `ingress.replicas: 0` and `ingress.service.type:
  ClusterIP` give no nginx pod and no second load balancer. The `armonik-ingress-gui` Service stays: the GUI
  route targets it.
- **The chart's Gateway API objects stay off** (`ingress.gateway.enabled`, `ingress.httpRoute.enabled`): it only
  renders an `HTTPRoute`, which breaks gRPC.
- **Grafana serves `/grafana/` itself** (`dependencies.grafana.env`: `GF_SERVER_ROOT_URL` with the path,
  `GF_SERVER_SERVE_FROM_SUB_PATH=true`). nginx used to strip the prefix and rewrite the HTML; Envoy does not.
  These go through `env` because the chart rejects a path in `grafana.ini` `root_url` while its nginx exists.
  Keep `dependencies.grafana.enabled` and `grafana.enabled` of `armonik-gateway.yaml` in sync.

## Before deploying: customer environment checklist

Answer these with the customer first. Each one maps to a value below.

| Question | Why | Where it goes |
|---|---|---|
| Internal or internet-facing NLB? | Scheme of the NLB | `loadBalancer.scheme` |
| Which subnets host the NLB? One per AZ the Envoy pods may run in | The LBC picks subnets by tag unless told otherwise | Tags, or `loadBalancer.annotations` (see below) |
| Are those subnets tagged `kubernetes.io/role/internal-elb=1` (internal) or `kubernetes.io/role/elb=1` (public)? | LBC subnet discovery. Our Terraform tags its own VPC; the customer's may not be | If not: explicit subnet IDs |
| LBC version, and does it manage Services (not only Ingresses)? | `aws-load-balancer-type: external` needs LBC v2.2+ | Nothing, or upgrade |
| Which CIDRs must reach the NLB? | LBC v2.6+ creates a frontend security group open to `0.0.0.0/0` on the listener ports unless restricted | `loadBalancer.annotations` |
| Can the NLB reach the Envoy pod IPs? | IP targets: traffic goes straight to the pods. The LBC adds the rules to the node security group (`manage-backend-security-group-rules`, on by default) | Check if the customer manages security groups by hand, or uses security groups for pods |
| Is the `core` node label present (`armonik.aneo.fr/node-pool: core`)? | Envoy's nodeSelector | `nodeSelector` in `values/armonik-gateway.yaml` |
| Registry with authentication (Artifactory)? | The Envoy images are pulled in `envoy-gateway-system` | `registry-credentials` Secret in that namespace |
| Customer NetworkPolicies, or a default-deny? | Envoy (`envoy-gateway-system`) must reach the control plane (pod port 1080), GUI (1080), Grafana (3000) and Seq (80) in `$ARMONIK_NS` | A policy admitting the Envoy pods (label `gateway.envoyproxy.io/owning-gateway-name: armonik`) |
| Is port 8080 (Seq) wanted on the NLB? | Seq has no authentication by default | `ports.seq: 0` drops it |

Check the LBC already in place:

```sh
kubectl get deploy -A -l app.kubernetes.io/name=aws-load-balancer-controller \
  -o jsonpath='{range .items[*]}{.metadata.namespace} {.spec.template.spec.containers[0].image}{"\n"}{end}'
```

## Configuration: `values/armonik-gateway.yaml`

`armonikRelease` must be the name of the `armonik` release: the routes target `<armonikRelease>-control-plane`,
`<armonikRelease>-ingress-gui`, `<armonikRelease>-grafana` and `<armonikRelease>-seq`.

**NLB exposure.** Pick one:

```yaml
# A. Internal, subnets discovered by tag (kubernetes.io/role/internal-elb=1)
loadBalancer:
  scheme: internal

# B. Internal, explicit subnets (no tags needed): one private subnet per AZ
loadBalancer:
  scheme: internal
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-0aaa,subnet-0bbb,subnet-0ccc

# C. Internet-facing, as in the demo (public subnets, kubernetes.io/role/elb=1 or explicit IDs)
loadBalancer:
  scheme: internet-facing
```

Optional annotations, under `loadBalancer.annotations`:

```yaml
# Restrict who reaches the NLB (frontend security group)
service.beta.kubernetes.io/load-balancer-source-ranges: 10.0.0.0/8
# Spread traffic across AZs evenly when Envoy replicas are not one per AZ
service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
```

**TLS.** Off (`tls.enabled: false`): the listeners serve plain HTTP and h2c, and clients use
`http://<nlb>:5001`.

**Grafana.** `grafana.enabled: true` routes `/grafana/` to the chart's Grafana. If the customer brings its own,
set it to `false` here and `dependencies.grafana.enabled: false` in `values/armonik.yaml`
(see [grafana-dashboards.md](grafana-dashboards.md)).

**Pull secrets.** `imagePullSecrets: [{name: registry-credentials}]` is passed to the Envoy pods through the
`EnvoyProxy`. With the ECR pull-through cache the Secret is absent and the reference is ignored.

## Deployment

Variables used below (from `values/env.sh`, or set by hand): `ARMONIK_NS`, `CHARTS_DOCKERHUB`, `REG_DOCKERHUB`,
`EG_VERSION`, `V=generated/values` (values rendered by the `envsubst` loop of the README).

The customer's LBC replaces our `aws-load-balancer-controller` release: skip it.

Order, after `armonik-operators`:

```sh
# 0. Artifactory with authentication only: pull secret in the Envoy Gateway namespace
kubectl create namespace envoy-gateway-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry registry-credentials -n envoy-gateway-system \
  --docker-server="$ARTIFACTORY" --docker-username="$ARTIFACTORY_USER" --docker-password="$ARTIFACTORY_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# 1. Envoy Gateway controller and CRDs
helm upgrade --install eg "oci://$CHARTS_DOCKERHUB/envoyproxy/gateway-helm" --version "$EG_VERSION" \
  -n envoy-gateway-system --create-namespace -f $V/envoy-gateway.yaml --wait

# 2. ArmoniK: creates the backend Services
helm upgrade --install armonik "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" \
  -n "$ARMONIK_NS" --create-namespace -f $V/armonik.yaml --wait --timeout 15m

# 3. Gateway, routes, policies: Envoy Gateway then deploys Envoy and the LBC creates the NLB
helm upgrade --install armonik-gateway ./charts/armonik-gateway \
  -n "$ARMONIK_NS" -f $V/armonik-gateway.yaml --wait
```

`eg` must come before `armonik-gateway` (it brings the CRDs), and the LBC must be running before step 3.

## Verification

```sh
# Accepted by the controller, then programmed (Envoy running, Service created)
kubectl get gatewayclass armonik                       # ACCEPTED True
kubectl get gateway armonik -n "$ARMONIK_NS"           # PROGRAMMED True, ADDRESS = NLB hostname
kubectl get grpcroute,httproute -n "$ARMONIK_NS"
kubectl describe grpcroute armonik-api -n "$ARMONIK_NS" | grep -A3 Conditions   # Accepted, ResolvedRefs

# Envoy pods and the NLB
kubectl get pods,svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=armonik
NLB=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=armonik \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# From a machine allowed to reach the NLB (targets take 2-3 min to turn healthy)
curl -sI "http://$NLB:5000/admin/en/"   # 200
curl -sI "http://$NLB:5000/grafana/"    # 200 or 302 to the login page
```

The API end to end: the htcmock client of the README (step 4), with `GrpcClient__Endpoint=http://$NLB:5001`.

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| GatewayClass not `Accepted` | `eg` not running, or the `EnvoyProxy` missing | `kubectl logs -n envoy-gateway-system deploy/envoy-gateway` |
| Gateway not `Programmed`, no Envoy pod | Envoy image pull (registry, pull secret), or no node matching the nodeSelector | `kubectl get events -n envoy-gateway-system` |
| Service stays `<pending>` | LBC: no matching subnets, IAM, or LBC not watching Services | `kubectl describe svc -n envoy-gateway-system ...` (events), LBC logs |
| NLB up, connections time out | Frontend security group (source ranges), or backend rules on the node security group | NLB target group health in the AWS console |
| Route `ResolvedRefs: False` | Backend Service missing: `armonikRelease` wrong, or Grafana/Seq disabled in `armonik.yaml` | `kubectl get svc -n "$ARMONIK_NS"` |
| gRPC `UNAVAILABLE` / `RST_STREAM` after a few minutes | Policy not attached | `kubectl get clienttrafficpolicy,backendtrafficpolicy -n "$ARMONIK_NS"`, status `Accepted` |
| 503 on all routes, backends healthy | A NetworkPolicy blocks `envoy-gateway-system` → `$ARMONIK_NS` | See the checklist |
| `/grafana/` redirect loop or 404 | `GF_SERVER_*` env missing in `dependencies.grafana` | `kubectl get deploy armonik-grafana -n "$ARMONIK_NS" -o yaml \| grep GF_SERVER` |

## Removal

`armonik-gateway` before `eg`: the controller must still run to delete the Envoy Service, so that the LBC deletes
the NLB. The other way round, the NLB is left behind.

```sh
helm uninstall armonik-gateway -n "$ARMONIK_NS" --wait
kubectl get svc -n envoy-gateway-system          # wait until the LoadBalancer Service is gone
helm uninstall eg -n envoy-gateway-system        # the CRDs stay, by Helm design
```

## Differences with nginx

| nginx | Envoy |
|---|---|
| Seq under `/seq/`, HTML rewritten | Seq on its own port, 8080 |
| `/grafana/` stripped and HTML rewritten | Grafana serves `/grafana/` itself |
| GUI language from `Accept-Language` | Redirect to `/admin/en/` |
| `/static/` (GUI environment banner) | Not served |
| mTLS, client certificate passed to Core | Not configured (Envoy supports it: `ClientTrafficPolicy` `tls.clientValidation`) |
| One Service in `$ARMONIK_NS` | Envoy and its Service in `envoy-gateway-system` |

# Envoy Gateway entry point

Envoy Gateway replaces the ArmoniK nginx as the only entry point. This page covers deploying it in a
customer cluster and VPC.

```
client ──► NLB (5001 / 5000 / 8080)            created by the customer's AWS Load Balancer Controller
       ──► Envoy pods (envoy-gateway-system)   created by Envoy Gateway
             ├─ gRPC armonik.*  ──► armonik-control-plane:5001
             ├─ /admin/*        ──► armonik-ingress-gui:1080   (/ redirects to /admin/en/)
             ├─ /grafana/*      ──► armonik-grafana:80
             └─ :8080           ──► armonik-seq:80
```

## Components

- **`eg`** (chart `envoyproxy/gateway-helm`, `values/envoy-gateway.yaml`): the Envoy Gateway controller and the
  Gateway API CRDs.
- **`armonik-gateway`** (`charts/armonik-gateway`, `values/armonik-gateway.yaml`): the ArmoniK configuration:
  - `gatewayclass.yaml` hands the `armonik` class to Envoy Gateway, with the `EnvoyProxy` as its parameters.
  - `envoyproxy.yaml` sets the Envoy pods (replicas, `core` nodes, pull secrets) and their `LoadBalancer`
    Service. The LBC annotations on that Service make it an NLB with IP targets.
  - `gateway.yaml` defines the `grpc` (5001), `http` (5000) and `seq` (8080) listeners, all plain HTTP/h2c.
  - `routes.yaml` holds a `GRPCRoute` for the API (it makes Envoy talk HTTP/2 to the control plane), and
    `HTTPRoute`s for the GUI, Grafana and Seq.
  - `policies.yaml` lifts Envoy's 5 min idle and 15 s request timeouts: ArmoniK gRPC streams last as long as a
    task runs.
- **`values/armonik.yaml`**:
  - The nginx stays but is idle: `ingress.replicas: 0`, `service.type: ClusterIP`. The chart's own Gateway
    API objects are off. The subchart cannot be disabled because it also carries the GUI.
  - Grafana serves `/grafana/` itself, through `GF_SERVER_ROOT_URL` and `GF_SERVER_SERVE_FROM_SUB_PATH`.

## Customer checklist

| Question | Value |
|---|---|
| Internal or internet-facing NLB? | `loadBalancer.scheme` |
| Which subnets? Are they tagged `kubernetes.io/role/internal-elb=1` (or `elb=1`)? | If not: `aws-load-balancer-subnets` annotation |
| Which CIDRs may reach the NLB? | `load-balancer-source-ranges` annotation |
| LBC version is v2.2 or later, and it handles Services? | – |
| Do the nodes carry the label `armonik.aneo.fr/node-pool: core`? | `nodeSelector` |
| Is the registry authenticated? | Secret `registry-credentials` in `envoy-gateway-system` |
| Is there a default-deny NetworkPolicy? | Allow `envoy-gateway-system` → `$ARMONIK_NS` |
| Should Seq be exposed? It has no authentication. | `ports.seq: 0` drops it |

## Configuration (`values/armonik-gateway.yaml`)

```yaml
armonikRelease: armonik          # name of the armonik release: the routes target its Services
loadBalancer:
  scheme: internal
  annotations:                   # only if the subnets are not tagged / to restrict sources
    service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-0aaa,subnet-0bbb,subnet-0ccc
    service.beta.kubernetes.io/load-balancer-source-ranges: 10.0.0.0/8
tls:
  enabled: false
```

## Deployment

Skip our `aws-load-balancer-controller` release: the customer's LBC is used. The other releases run after
`armonik-operators`:

```sh
helm upgrade --install eg "oci://$CHARTS_DOCKERHUB/envoyproxy/gateway-helm" --version "$EG_VERSION" \
  -n envoy-gateway-system --create-namespace -f $V/envoy-gateway.yaml --wait
helm upgrade --install armonik "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" \
  -n "$ARMONIK_NS" --create-namespace -f $V/armonik.yaml --wait --timeout 15m
helm upgrade --install armonik-gateway ./charts/armonik-gateway \
  -n "$ARMONIK_NS" -f $V/armonik-gateway.yaml --wait
```

## Verification

```sh
kubectl get gateway armonik -n "$ARMONIK_NS"       # PROGRAMMED True, ADDRESS = NLB hostname
kubectl get grpcroute,httproute -n "$ARMONIK_NS"
NLB=$(kubectl get gateway armonik -n "$ARMONIK_NS" -o jsonpath='{.status.addresses[0].value}')
curl -sI "http://$NLB:5000/admin/en/"              # 200, once the NLB targets are healthy (2-3 min)
```

The API end to end: the README's htcmock client with `GrpcClient__Endpoint=http://$NLB:5001`.

If the Service stays `<pending>`, check the LBC: subnets, IAM, and the events of the Service in
`envoy-gateway-system`.

## Removal

Uninstall `armonik-gateway` before `eg`. Otherwise no controller is left to delete the Envoy Service, and the
NLB is left behind.

```sh
helm uninstall armonik-gateway -n "$ARMONIK_NS" --wait
helm uninstall eg -n envoy-gateway-system
```

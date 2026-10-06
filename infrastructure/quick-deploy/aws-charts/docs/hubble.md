# Hubble

What to look at in Hubble (installed with Cilium, `values/cilium.yaml`) when ArmoniK runs, starting with an htcmock
run. Every flow and filter below was checked on a deployment of this quick-deploy.

## Access

```sh
# UI: http://localhost:12000
kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# CLI (https://github.com/cilium/hubble/releases): hubble observe reads localhost:4245 by default
kubectl port-forward -n kube-system svc/hubble-relay 4245:80
hubble observe -n armonik -f
```

Without the CLI installed, the Cilium agent image ships it. It runs on the host network, so it reaches the relay by
its ClusterIP:

```sh
RELAY=$(kubectl get svc -n kube-system hubble-relay -o jsonpath='{.spec.clusterIP}')
kubectl exec -n kube-system ds/cilium -c cilium-agent -- hubble observe --server $RELAY:80 -n armonik -f
```

The UI shows one namespace at a time (`armonik` is the one to pick), but a flow to or from another namespace (Envoy,
Prometheus, KEDA, CoreDNS) still shows up in it. Flows are listed live; the verdict dropdown keeps the dropped ones.

## Who talks to whom

The ArmoniK pods already carry labels to filter on: there is no need to add any.

| Flow | Port | Filter |
|---|---|---|
| Client → Envoy (NLB, or a pod in the cluster) | 5001 | `--to-label gateway.envoyproxy.io/owning-gateway-name=armonik` |
| Envoy → control plane (gRPC API) | 1080 | `--to-label app.kubernetes.io/component=control-plane` |
| Control plane, compute plane → RDS | 5432 | `-n armonik --to-port 5432` |
| Control plane, compute plane → S3 and SQS | 443 | `-n armonik --to-identity world --to-port 443` |
| Compute plane of a partition | | `--label armonik.fr/partition=htcmock` |
| KEDA → metrics exporter (scaling metric) | 1080 | `--from-pod armonik-operators/keda-operator --to-namespace armonik` |
| Prometheus → control plane (1081), metrics exporter, agents (1080) | | `--from-pod armonik-operators/prometheus-armonik-operators-kube-pro-prometheus-0` |
| fluent-bit → Seq (logs) | 5341 | `--to-label app=seq` |
| Anything a NetworkPolicy refuses (`armonik-hardening.yaml`) | | `--verdict DROPPED --not --protocol icmpv6` |

The compute plane never calls the control plane: the agent reads and writes the same backends directly (RDS, SQS,
S3). The agent ↔ worker traffic stays inside the pod and does not show up.

AWS services are `world` with an IP, not a name: Hubble only shows DNS names with an L7 DNS policy, which this
deployment does not have. To tell them apart: RDS is in the VPC (`10.0.x.x:5432`, `terraform output postgresql`),
S3 and SQS are public AWS addresses on 443 (`getent hosts sqs.<region>.amazonaws.com`, `s3.<region>.amazonaws.com`).

## Follow an htcmock run

Three terminals before starting the client (README step 4, or from inside the cluster, `docs/reference.md`):

```sh
# 1. New connections of ArmoniK, one line each (SYN only), without the kubelet probes; grep drops
#    fluent-bit, which keeps opening connections to the API server (a second --not would not, see below)
hubble observe -n armonik -f --tcp-flags SYN \
  --to-port 5001 --to-port 1080 --to-port 5432 --to-port 443 \
  --not --label reserved:host | grep -v armonik-fluent-bit
# 2. KEDA scaling the partition, Karpenter adding nodes
kubectl get pods -n armonik -l armonik.fr/partition=htcmock -w
kubectl get nodeclaims -w
# 3. Anything refused
hubble observe -f --verdict DROPPED --not --protocol icmpv6
```

What shows up, in order:

1. **Submission.** The client opens a gRPC connection to Envoy (`world` → `envoy-armonik-…:5001` through the NLB,
   `armonik/htcmock-client` → `envoy-armonik-…:5001` from inside), and Envoy one to the control plane
   (`envoy-armonik-… → armonik-control-plane-…:1080`). Few lines: the connections are long-lived gRPC streams.
2. **The control plane stores the session and the root task.** `armonik-control-plane-… → 10.0.x.x:5432 (world)`
   (RDS), then 443 to S3 (payloads) and SQS (the task is queued).
3. **Scale-up.** KEDA polls the metrics exporter (`keda-operator → metrics-exporter:1080`), which reads the queue
   length; KEDA scales `armonik-compute-plane-htcmock`. The pods stay `Pending` until Karpenter's `workers` node is
   ready (about a minute), then fluent-bit starts there too.
4. **Tasks run.** Each `armonik-compute-plane-htcmock-…` pod: SQS (dequeue), S3 (payloads in, results out), RDS
   (task states). The root task's worker creates the subtasks the same way: the agent writes them to RDS, S3 and
   SQS, which feeds steps 3 and 4 again. Prometheus starts scraping the new pods on 1080.
5. **Logs.** fluent-bit → `armonik-seq-…:5341`, and fluent-bit → API server (443, a `10.0.x.x` CIDR identity) for
   the pod metadata.
6. **End.** The client's last calls go through Envoy again, the compute plane connections stop, and KEDA scales the
   partition to 0 about 5 minutes later (cooldown).

## Noise and limits

- `(host)` flows are the kubelet probes; `--not --label reserved:host` hides them.
- Several `--not` flags are combined with AND into one exclusion: `--not --label reserved:host --not --port 53` only
  hides host flows on port 53. Use one `--not` per command, or filter positively (same flag repeated = OR, as with
  `--to-port` above).
- `--label` cannot be used with `--from-label`/`--to-label` in the same command.
- `Unsupported L3 protocol DROPPED (ICMPv6 …)` on a pod start is harmless (IPv6 neighbor discovery on an IPv4
  cluster): `--not --protocol icmpv6`.
- L3/L4 only: no gRPC method or HTTP path without an L7 policy.
- Each node keeps only its last 4095 flows: on a busy cluster `--since 10m` may already be gone. Follow with `-f`
  during the run rather than looking back afterwards.

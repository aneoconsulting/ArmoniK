# Using your own Grafana

`values/armonik.yaml` sets `dependencies.grafana.enabled: false`: the release deploys no Grafana. The
Prometheus it needs is the one of `armonik-operators` (kube-prometheus-stack), which stays. Three things
remain to connect your Grafana to it.

| What | Rendered by the chart when Grafana is disabled? |
|---|---|
| Prometheus, scraping the ArmoniK `ServiceMonitor`s and `PodMonitor`s | Yes, in `armonik-operators` |
| Kubernetes and node dashboards of kube-prometheus-stack (ConfigMaps labelled `grafana_dashboard`, in the operators namespace) | Yes |
| ArmoniK dashboards and the Prometheus datasource | **No**: both are rendered only with `dependencies.grafana.enabled` |

## 1. The datasource

Any Prometheus datasource of your Grafana works: the dashboards pick it through a `datasource` template
variable, not a fixed uid. Its URL is the Prometheus Service of the operators release:

```
http://prometheus-prometheus.<operators namespace>.svc:9090
```

That name resolves inside the cluster only. A Grafana outside it needs the Prometheus exposed (an internal
load balancer or an ingress of yours), or the metrics sent to your own Prometheus with the
`kube-prometheus.prometheus.prometheusSpec.remoteWrite` value of `armonik-operators`.

## 2. The ArmoniK dashboards

They ship inside the `armonik` chart, in `static-confs/grafana-dashboards/`:

```sh
helm pull "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" --untar --untardir /tmp/armonik-chart
ls /tmp/armonik-chart/armonik/static-confs/grafana-dashboards
```

`dashboard-armonik.json` (ArmoniK at a glance), `dashboard-compute.json` (compute plane execution) and
`dashboard-taskhandler.json` are the ones to show. The `mongodb` and `rabbitmq` ones are of no use with this
scenario. Two ways to load them:

**With the Grafana sidecar** (Grafana in this cluster, started with the k8s-sidecar of the Grafana chart,
which loads the ConfigMaps labelled `grafana_dashboard` and, with `folderAnnotation`, sorts them in folders):

```sh
D=/tmp/armonik-chart/armonik/static-confs/grafana-dashboards
kubectl create configmap armonik-dashboards -n monitoring \
  --from-file=$D/dashboard-armonik.json \
  --from-file=$D/dashboard-compute.json \
  --from-file=$D/dashboard-taskhandler.json
kubectl label configmap armonik-dashboards -n monitoring grafana_dashboard=1
kubectl annotate configmap armonik-dashboards -n monitoring grafana_dashboard_folder=ArmoniK
```

The sidecar must watch that namespace (`sidecar.dashboards.searchNamespace`).

**With the Grafana HTTP API** (any Grafana, a service account token with the Editor role):

```sh
for f in $D/dashboard-armonik.json $D/dashboard-compute.json $D/dashboard-taskhandler.json; do
  jq '{dashboard: (. + {id: null}), overwrite: true}' "$f" |
    curl -fsS -X POST "$GRAFANA_URL/api/dashboards/db" \
      -H "Authorization: Bearer $GRAFANA_TOKEN" -H 'Content-Type: application/json' -d @-
done
```

## 3. Reaching your Grafana

Envoy Gateway is the only entry point and has no `/grafana/` route (the ArmoniK nginx had one, see
`docs/reference.md`): give your users your Grafana URL directly. `ingress.grafana_url`, which
`values/armonik.yaml` fills from `GRAFANA_URL`, only sets the link the admin GUI shows.

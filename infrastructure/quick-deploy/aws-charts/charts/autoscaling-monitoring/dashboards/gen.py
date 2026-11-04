# Writes autoscaling.json next to this file: python3 gen.py. Edit the panels here, not in the JSON.
import json, pathlib

P = "${partition}"
POD = f'pod=~"armonik-compute-plane-{P}-.*"'
# The worker is a native sidecar: its requests are in the init container metric
REQ = '{__name__=~"kube_pod_(init_)?container_resource_requests",resource="cpu"'
WORKERS = 'max by (node) (kube_node_labels{label_karpenter_sh_nodepool="workers"})'

PANELS = [
    ("Tasks of the partition", "short", [
        (f"armonik_{P}_tasks_submitted", "waiting (Submitted)"),
        (f"armonik_{P}_tasks_dispatched", "dispatched"),
        (f"armonik_{P}_tasks_processing", "processing"),
        (f'max(keda_scaler_metrics_value{{scaledObject="armonik-compute-plane-{P}"}})', "KEDA input (queued)"),
    ]),
    ("Pods of the partition", "short", [
        (f'max(kube_horizontalpodautoscaler_status_desired_replicas{{namespace="armonik",horizontalpodautoscaler="keda-hpa-armonik-compute-plane-{P}"}})', "HPA desired"),
        (f'max(kube_deployment_status_replicas{{namespace="armonik",deployment="armonik-compute-plane-{P}"}})', "created"),
        (f'sum(kube_pod_status_phase{{namespace="armonik",{POD},phase="Pending"}})', "pending"),
        (f'max(kube_deployment_status_replicas_available{{namespace="armonik",deployment="armonik-compute-plane-{P}"}})', "ready"),
        (f"armonik_{P}_tasks_processing", "busy (processing tasks)"),
    ]),
    ("Cores of the workers node pool", "short", [
        (f'sum(kube_node_status_capacity{{resource="cpu"}} * on (node) group_left () {WORKERS})', "capacity (workers nodes)"),
        (f'sum({REQ}}} * on (node) group_left () {WORKERS})', "requested (all pods on workers nodes)"),
        (f'sum({REQ},namespace="armonik",{POD}}} * on (namespace, pod) group_left () max by (namespace, pod) (kube_pod_status_phase{{phase="Running"}} == 1))', "requested (running pods of the partition)"),
        (f"armonik_{P}_tasks_processing", "busy (1 per running task)"),
        (f'sum(rate(container_cpu_usage_seconds_total{{namespace="armonik",{POD},container!="",container!="POD"}}[1m]))', "used (pods of the partition)"),
    ]),
    ("Workers nodes", "short", [
        ('count by (label_karpenter_sh_capacity_type) (kube_node_labels{label_karpenter_sh_nodepool="workers"})', "nodes {{label_karpenter_sh_capacity_type}}"),
        ('sum(increase(karpenter_nodeclaims_created_total{nodepool="workers"}[1m]))', "nodeclaims created / min"),
        ('sum(increase(karpenter_nodeclaims_disrupted_total{nodepool="workers"}[1m]))', "nodeclaims disrupted / min"),
    ]),
    ("Scaling latencies", "s", [
        ('max(keda_scaler_metrics_latency_seconds{scaledObject="armonik-compute-plane-' + P + '"})', "KEDA scaler latency"),
        # Pods that needed a new node: creation -> bound, and creation -> running (node launch + image pull)
        ('histogram_quantile(0.5, sum by (le) (rate(karpenter_pods_provisioning_bound_duration_seconds_bucket[2m])))', "new-node pod bound p50"),
        ('histogram_quantile(0.5, sum by (le) (rate(karpenter_pods_provisioning_startup_duration_seconds_bucket[2m])))', "new-node pod running p50"),
        ('histogram_quantile(0.95, sum by (le) (rate(karpenter_pods_provisioning_startup_duration_seconds_bucket[2m])))', "new-node pod running p95"),
    ]),
]


def panel(i, title, unit, targets):
    return {
        "id": i + 1,
        "type": "timeseries",
        "title": title,
        "datasource": {"type": "prometheus", "uid": "${datasource}"},
        "gridPos": {"x": 0, "y": i * 8, "w": 24, "h": 8},
        "fieldConfig": {"defaults": {"unit": unit, "custom": {"lineWidth": 2, "fillOpacity": 0, "spanNulls": True}}, "overrides": []},
        "options": {"legend": {"displayMode": "table", "placement": "right", "calcs": ["max", "mean"]}, "tooltip": {"mode": "multi", "sort": "none"}},
        "targets": [
            {"refId": chr(65 + j), "expr": expr, "legendFormat": legend, "interval": "10s", "datasource": {"type": "prometheus", "uid": "${datasource}"}}
            for j, (expr, legend) in enumerate(targets)
        ],
    }


dashboard = {
    "uid": "armonik-autoscaling",
    "title": "ArmoniK autoscaling",
    "tags": ["armonik", "autoscaling"],
    "timezone": "browser",
    "schemaVersion": 39,
    "refresh": "10s",
    "time": {"from": "now-30m", "to": "now"},
    "graphTooltip": 1,
    "templating": {"list": [
        {"name": "datasource", "type": "datasource", "query": "prometheus", "current": {}, "hide": 0},
        {"name": "partition", "type": "custom", "query": "__PARTITIONS__", "multi": False, "includeAll": False, "current": {}},
    ]},
    "panels": [panel(i, *p) for i, p in enumerate(PANELS)],
}

out = pathlib.Path(__file__).with_name("autoscaling.json")
out.write_text(json.dumps(dashboard, indent=2) + "\n")

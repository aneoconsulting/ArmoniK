# Writes autoscaling.json next to this file: python3 gen.py. Edit the panels here, not in the JSON.
import json, pathlib

P = "${partition}"
POD = f'pod=~"armonik-compute-plane-{P}-.*"'
# The worker is a native sidecar: its requests are in the init container metric
REQ = '{__name__=~"kube_pod_(init_)?container_resource_requests",resource="cpu"'
WORKERS = 'max by (node) (kube_node_labels{label_karpenter_sh_nodepool="workers"})'

# Details, in a collapsed row under the main graph
DETAILS = [
    ("Tasks of the partition", "short", [
        (f"armonik_{P}_tasks_submitted", "waiting (Submitted)"),
        (f"armonik_{P}_tasks_dispatched", "dispatched"),
        (f"armonik_{P}_tasks_processing", "processing"),
        (f'max(keda_scaler_metrics_value{{scaledObject="armonik-compute-plane-{P}"}})', "KEDA input (queued)"),
    ]),
    # The target in PromQL (rules/autoscaling.rules.yaml), computed for every partition
    ("PromQL target (armonik:scaler_target)", "short", [
        (f'armonik:scaler_target{{partition="{P}"}}', "target workers"),
        (f'armonik:scaler_flow_workers{{partition="{P}"}}', "F: incoming flow"),
        (f'armonik:scaler_running_workers{{partition="{P}"}}', "R: running tasks"),
        (f'armonik:scaler_waiting_workers{{partition="{P}"}}', "W: queue"),
        (f'armonik:tasks_arrival_rate{{partition="{P}"}}', "arrivals (tasks/s)"),
        (f'armonik:tasks_completion_rate{{partition="{P}"}}', "completions (tasks/s)"),
        (f'armonik:task_duration_seconds{{partition="{P}"}}', "task duration, used by the target (s)"),
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


DS = {"type": "prometheus", "uid": "${datasource}"}
DEPLOY = f'namespace="armonik",deployment="armonik-compute-plane-{P}"'
HPA = f'namespace="armonik",horizontalpodautoscaler="keda-hpa-armonik-compute-plane-{P}"'
READY = f"max(kube_deployment_status_replicas_available{{{DEPLOY}}})"
# Pods running a task: tasks in Processing, at most the ready pods (post-processing overlaps the next task)
BUSY = f"clamp_max(max(armonik_{P}_tasks_processing), scalar({READY}))"
IDLE = f"({READY} - {BUSY})"

# The one graph: pods asked (target, HPA), paid (ready), useful (busy), and the queue on the right axis
MAIN = [
    (f"clamp_max(max(armonik:scaler_target{{partition=\"{P}\"}}), scalar(max(kube_horizontalpodautoscaler_spec_max_replicas{{{HPA}}})))",
     "target PromQL"),
    (f"max(kube_horizontalpodautoscaler_status_desired_replicas{{{HPA}}})", "desired (HPA)"),
    (READY, "ready (payés)"),
    (BUSY, "busy (utiles)"),
    (f"max(armonik_{P}_tasks_submitted)", "en attente"),
    (f"max(armonik_{P}_tasks_pending) + max(armonik_{P}_tasks_creating)", "en attente de dépendances"),
]

# Over the displayed time range: the three numbers to compare two runs
STATS = [
    ("Pic de pods prêts", f"max_over_time({READY}[$__range:5s])", "short"),
    ("Pod·s inactifs", f"sum_over_time({IDLE}[$__range:5s]) * 5", "short"),
    ("Temps avec une file non vide", f"count_over_time((max(armonik_{P}_tasks_submitted) > 0)[$__range:5s]) * 5", "s"),
]


def override(name, props):
    return {"matcher": {"id": "byName", "options": name}, "properties": [{"id": k, "value": v} for k, v in props.items()]}


def main_panel(y):
    return {
        "id": 1,
        "type": "timeseries",
        "title": "Pods : demandés, payés, utiles",
        "description": "target PromQL : armonik:scaler_target, calculée pour toutes les partitions (même celles sur queued / 2). "
                       "Écart horizontal desired → ready : cold start. Aire claire au-dessus de busy : pods payés pour rien. "
                       "target sous desired : le HPA retient la descente. Axe droit : tâches.",
        "datasource": DS,
        "gridPos": {"x": 0, "y": y, "w": 24, "h": 14},
        "fieldConfig": {
            "defaults": {"unit": "short", "custom": {"lineWidth": 2, "fillOpacity": 0, "spanNulls": True}},
            "overrides": [
                override("target PromQL", {"custom.lineStyle": {"fill": "dash", "dash": [4, 4]}}),
                override("desired (HPA)", {"custom.lineWidth": 1}),
                override("ready (payés)", {"custom.fillOpacity": 15}),
                override("busy (utiles)", {"custom.fillOpacity": 45}),
                override("en attente", {"custom.axisPlacement": "right", "unit": "short", "custom.axisLabel": "tâches"}),
                override("en attente de dépendances", {"custom.axisPlacement": "right", "custom.lineStyle": {"fill": "dot", "dash": [2, 6]}}),
            ],
        },
        "options": {"legend": {"displayMode": "list", "placement": "bottom"}, "tooltip": {"mode": "multi", "sort": "none"}},
        "targets": [
            {"refId": chr(65 + j), "expr": expr, "legendFormat": legend, "interval": "5s", "datasource": DS}
            for j, (expr, legend) in enumerate(MAIN)
        ],
    }


def stat_panel(i, title, expr, unit):
    return {
        "id": 100 + i,
        "type": "stat",
        "title": title,
        "datasource": DS,
        "gridPos": {"x": i * 8, "y": 0, "w": 8, "h": 4},
        "fieldConfig": {"defaults": {"unit": unit, "decimals": 0}, "overrides": []},
        "options": {"reduceOptions": {"calcs": ["lastNotNull"]}, "colorMode": "none", "graphMode": "none"},
        "targets": [{"refId": "A", "expr": expr, "instant": True, "datasource": DS}],
    }


def panel(i, title, unit, targets, y):
    return {
        "id": 10 + i,
        "type": "timeseries",
        "title": title,
        "datasource": DS,
        "gridPos": {"x": 0, "y": y + i * 8, "w": 24, "h": 8},
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
    "panels": [
        *[stat_panel(i, *st) for i, st in enumerate(STATS)],
        main_panel(4),
        {"id": 99, "type": "row", "title": "Détails", "collapsed": True, "gridPos": {"x": 0, "y": 18, "w": 24, "h": 1},
         "panels": [panel(i, *d, 19) for i, d in enumerate(DETAILS)]},
    ],
}

out = pathlib.Path(__file__).with_name("autoscaling.json")
out.write_text(json.dumps(dashboard, indent=2) + "\n")

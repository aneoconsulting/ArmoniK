#!/usr/bin/env python3
"""Writes the bench dashboards (Grafana JSON) next to this file: python3 gen.py. Edit the panels here, not in the JSON.

Ported from the GCP bench (gcp-charts/monitoring/gen-dashboards.py): Cloud Monitoring becomes CloudWatch (Aurora,
RDS Proxy, SQS, S3), the ComputeClasses become the Karpenter node pools. The __PLACEHOLDERS__ are replaced by
templates/dashboards.yaml with the values of the release (bench-monitoring.tf).
"""
import json
from pathlib import Path

OUT = Path(__file__).parent
PROM = {"type": "prometheus", "uid": "PBFA97CFB590B2093"}  # the chart's datasource (grafana-datasource-armonik)
CW = {"type": "cloudwatch", "uid": "cloudwatch"}
PG = {"type": "grafana-postgresql-datasource", "uid": "armonik-postgresql"}
MIXED = {"type": "datasource", "uid": "-- Mixed --"}

NS = "__NAMESPACE__"
CP = f'namespace="{NS}",pod=~"armonik-compute-plane-$partition-[a-z0-9]+-[a-z0-9]+"'
# The steps that a bench script writes as Grafana annotations (tag bench), shown as regions on every dashboard
STEPS = {"name": "Bench steps", "enable": True, "iconColor": "rgba(0, 150, 255, 0.6)",
         "datasource": {"type": "grafana", "uid": "-- Grafana --"},
         "target": {"type": "tags", "tags": ["bench"], "matchAny": True, "limit": 200}}


class Board:
    def __init__(self, uid, title, description, refresh="30s"):
        self.uid, self.title, self.description, self.refresh = uid, title, description, refresh
        self.panels, self.y, self.x, self.row_h, self.next_id = [], 0, 0, 0, 1
        self.templating = []

    def _place(self, w, h):
        if self.x + w > 24:
            self.x, self.y = 0, self.y + self.row_h
            self.row_h = 0
        pos = {"x": self.x, "y": self.y, "w": w, "h": h}
        self.x += w
        self.row_h = max(self.row_h, h)
        return pos

    def row(self, title):
        if self.x:
            self.x, self.y, self.row_h = 0, self.y + self.row_h, 0
        self.panels.append({"type": "row", "title": title, "id": self._id(), "collapsed": False,
                            "gridPos": {"x": 0, "y": self.y, "w": 24, "h": 1}, "panels": []})
        self.y += 1

    def _id(self):
        self.next_id += 1
        return self.next_id

    def panel(self, kind, title, ds, targets, w=8, h=8, unit=None, description=None, options=None, field=None,
              overrides=None):
        # Every target carries its datasource: the panel takes the common one, or Mixed
        if ds is None:
            uids = {t["datasource"]["uid"] for t in targets}
            ds = targets[0]["datasource"] if len(uids) == 1 else MIXED
        p = {"type": kind, "title": title, "id": self._id(), "datasource": ds, "gridPos": self._place(w, h),
             "targets": [dict(t, refId=chr(65 + i), datasource=t.get("datasource", ds)) for i, t in enumerate(targets)],
             "fieldConfig": {"defaults": dict({"unit": unit} if unit else {}, **(field or {})),
                             "overrides": [{"matcher": {"id": "byName", "options": name},
                                            "properties": [{"id": k, "value": v} for k, v in props.items()]}
                                           for name, props in (overrides or {}).items()]},
             "options": options or {}}
        if description:
            p["description"] = description
        self.panels.append(p)

    def ts(self, title, targets, **kw):
        kw.setdefault("options", {"legend": {"displayMode": "table", "placement": "bottom", "calcs": ["mean", "max"]},
                                  "tooltip": {"mode": "multi"}})
        self.panel("timeseries", title, kw.pop("ds", None), targets, **kw)

    def stat(self, title, targets, **kw):
        self.panel("stat", title, kw.pop("ds", None), targets, w=kw.pop("w", 4), h=kw.pop("h", 4), **kw)

    def dump(self):
        return {"uid": self.uid, "title": self.title, "description": self.description, "tags": ["armonik", "bench"],
                "timezone": "utc", "schemaVersion": 39, "editable": True, "refresh": self.refresh,
                "time": {"from": "now-1h", "to": "now"}, "templating": {"list": self.templating},
                "annotations": {"list": [STEPS]}, "panels": self.panels}


def prom(expr, legend="__auto", instant=False):
    return {"expr": expr, "legendFormat": legend, "range": not instant, "instant": instant, "datasource": PROM}


def sql(query, fmt="time_series"):
    return {"rawSql": query, "format": fmt, "rawQuery": True, "editorMode": "code", "datasource": PG}


# CloudWatch: SEARCH expressions in code mode, which read only the exact dimension set of the schema and match the
# queues of the stack by name token. One point per minute (the standard resolution of these services), so the Sum
# statistics divided by 60 are rates per second.
def cw(schema, metric, filters, stat="Average", label="", per_second=False, total=False, period=60):
    expr = f"SEARCH('{{{schema}}} MetricName=\"{metric}\" {filters}', '{stat}', {period})"
    if total:
        expr = f"SUM({expr})"
    if per_second:
        expr = f"{expr} / {period}"
    return {"queryMode": "Metrics", "metricQueryType": 0, "metricEditorMode": 1, "expression": expr, "id": "",
            "region": "default", "label": label, "datasource": CW}


# Aurora: the writer is instance 0 of the cluster (aurora module of ArmoniK.Infra, one instance in the bench)
def rds(metric, stat="Average", label=None, **kw):
    return cw("AWS/RDS,DBInstanceIdentifier", metric, 'DBInstanceIdentifier="__AURORA_INSTANCE__"', stat,
              label if label is not None else metric, **kw)


def volume(metric, stat="Sum", label=None, **kw):
    return cw("AWS/RDS,DBClusterIdentifier", metric, 'DBClusterIdentifier="__AURORA_CLUSTER__"', stat,
              label if label is not None else metric, **kw)


def proxy(metric, stat="Average", label=None, **kw):
    return cw("AWS/RDS,ProxyName", metric, 'ProxyName="__PROXY__"', stat, label if label is not None else metric, **kw)


# Core names the queue of a partition <prefix>-<partition>[-<priority>]: the prefix is a name token of every queue
def sqs(metric, stat="Sum", label="${PROP('Dim.QueueName')}", **kw):
    return cw("AWS/SQS,QueueName", metric, "QueueName=__QUEUE_PREFIX__", stat, label, **kw)


# S3 request metrics of the bucket (aws_s3_bucket_metric of bench-monitoring.tf, filter EntireBucket)
def s3(metric, stat="Sum", label=None, **kw):
    return cw("AWS/S3,BucketName,FilterId", metric, 'BucketName="__BUCKET__" FilterId="EntireBucket"', stat,
              label if label is not None else metric, **kw)


ACU_HELP = ("Serverless v2: 1 ACU is about 2 GiB of memory with the matching CPU, by steps of 0.5. Empty with "
            "provisioned instances")
PERCENT_THRESHOLDS = {"thresholds": {"mode": "absolute", "steps": [
    {"color": "green", "value": None}, {"color": "orange", "value": 70}, {"color": "red", "value": 85}]}}

# ---------------------------------------------------------------------------------------------------------------------
# 1. Compute plane: what an agent/worker pair costs, and how the nodes are filled
# ---------------------------------------------------------------------------------------------------------------------
c = Board("armonik-bench-compute", "Bench - compute (agent/worker)",
          "Cost of an agent/worker pair per partition and node packing. CPU in millicores (1 min rate).")
# From the Deployments, which exist at 0 pod too, so that the variable is never empty
c.templating.append({"name": "partition", "label": "Partition", "type": "query", "datasource": PROM,
                     "query": {"query": f'label_values(kube_deployment_spec_replicas{{namespace="{NS}",deployment=~"armonik-compute-plane-.+"}}, deployment)',
                               "refId": "partition"},
                     "regex": "/armonik-compute-plane-(.+)/", "refresh": 2, "sort": 1, "current": {}})
pods = f'sum(kube_deployment_status_replicas_available{{namespace="{NS}",deployment="armonik-compute-plane-$partition"}})'
# The Karpenter pool of the partitions (kube_node_labels, allowlisted in values/armonik-operators.yaml)
workers = ' * on (node) group_left () (kube_node_labels{label_karpenter_sh_nodepool="workers"} > 0)'
nl = 'kube_node_labels{label_karpenter_sh_nodepool!=""}'
NODES = (f"count by (label_karpenter_sh_nodepool, label_node_kubernetes_io_instance_type, label_karpenter_sh_capacity_type) ({nl})",
         "{{label_karpenter_sh_nodepool}} {{label_node_kubernetes_io_instance_type}} {{label_karpenter_sh_capacity_type}}")

c.row("Load")
c.stat("Pods", [prom(pods)])
c.stat("Busy pods", [prom('sum({__name__="armonik_${partition}_tasks_processing"})')],
       description="Tasks a pod is processing right now (Core metrics exporter). Dispatched tasks are taken by an agent "
                   "but not started: they wait behind the running one")
c.stat("Busy ratio", [prom(f'sum({{__name__="armonik_${{partition}}_tasks_processing"}}) / {pods}')], unit="percentunit")
c.stat("Ended tasks/s", [prom('sum(armonik:tasks_ended:rate1m)')], unit="reqps",
       description="All partitions (Core records the end of a task without its partition)")
c.stat("Tasks/s per pod", [prom(f'sum(armonik:tasks_ended:rate1m) / {pods}')], unit="reqps",
       description="Ended tasks of all partitions over the pods of this one: right when a single partition runs")
c.stat("Queued", [prom('sum({__name__="armonik_${partition}_tasks_queued"})')])
c.ts("Tasks (Core metrics exporter)", [prom('sum({__name__="armonik_${partition}_tasks_queued"})', "queued"),
                                       prom('sum({__name__="armonik_${partition}_tasks_dispatched"})', "dispatched"),
                                       prom('sum({__name__="armonik_${partition}_tasks_processing"})', "processing"),
                                       prom(pods, "pods")], w=12)
c.ts("Throughput", [prom('sum(armonik:tasks_ended:rate1m)', "ended tasks/s (all partitions)"),
                    prom(f'sum(armonik:tasks_ended:rate1m) / {pods}', "per pod")],
     w=12, unit="reqps", description="Calls of the end-of-task statement of Core (pg_stat_statements, postgres_exporter): "
                                     "all partitions, per pod right when a single partition runs")

c.ts("Partition CPU (cores): used, requested, paid", [
    prom(f'sum(rate(container_cpu_usage_seconds_total{{{CP},container="{ct}"}}[1m]))', f"{ct} used") for ct in ["agent", "worker"]] + [
    # The worker is a restartable init container (native sidecar): its requests are in the init container metric
    prom(f'sum(kube_pod_container_resource_requests{{{CP},container="agent",resource="cpu"}}) + sum(kube_pod_init_container_resource_requests{{{CP},container="worker",resource="cpu"}})',
         "agent + worker requested"),
    prom(f'sum(kube_node_status_allocatable{{resource="cpu"}}{workers})', "workers nodes allocatable")],
     w=24, description="Used: what the pairs burn. Requested: what sizes the nodes. Allocatable: the vCPU of the workers nodes, what is paid")

for ct in ["agent", "worker"]:
    sel = f'partition="$partition",container="{ct}"'
    # The worker is a native sidecar: its requests and limits are in the init container metrics
    kind = "init_container" if ct == "worker" else "container"
    req = f'kube_pod_{kind}_resource_requests{{{CP},container="{ct}",resource="%s"}}'
    lim = f'kube_pod_{kind}_resource_limits{{{CP},container="{ct}",resource="%s"}}'
    c.row(f"{ct.capitalize()} container")
    c.ts(f"{ct} CPU (m)", [prom(f"avg(armonik:container_cpu_millicores:rate1m{{{sel}}})", "mean"),
                           prom(f"quantile(0.5, armonik:container_cpu_millicores:rate1m{{{sel}}})", "median"),
                           prom(f"quantile(0.95, armonik:container_cpu_millicores:rate1m{{{sel}}})", "p95"),
                           prom(f"max(armonik:container_cpu_millicores:rate1m{{{sel}}})", "max"),
                           prom(f"1000 * avg({req % 'cpu'})", "request"),
                           prom(f"1000 * avg({lim % 'cpu'})", "limit")])
    c.ts(f"{ct} memory (MiB, working set)", [
        prom(f"avg(armonik:container_memory_working_set_mib{{{sel}}})", "mean"),
        prom(f"max(armonik:container_memory_working_set_mib{{{sel}}})", "max"),
        prom(f"avg({req % 'memory'}) / 1048576", "request"),
        prom(f"avg({lim % 'memory'}) / 1048576", "limit")])
    c.ts(f"{ct} CPU throttled (max pod)", [
        prom(f"max(armonik:container_cpu_throttled_ratio:rate1m{{{sel}}})", "throttled")],
         unit="percentunit", description="Share of the CFS periods capped by the limit, on the worst pod")

c.row("Health")
c.stat("OOM killed containers", [prom(
    f'sum(kube_pod_container_status_last_terminated_reason{{{CP},reason="OOMKilled"}}) or vector(0)')])
c.stat("Restarts (range)", [prom(f'sum(increase(kube_pod_container_status_restarts_total{{{CP}}}[$__range])) or vector(0)',
                                 instant=True)])
c.ts("Restarts by container", [prom(f'sum by (container) (increase(kube_pod_container_status_restarts_total{{{CP}}}[5m]))')],
     w=16)

c.row("Nodes")
c.ts("Nodes by Karpenter pool, instance type and capacity type", [prom(*NODES)], w=12)
c.ts("Pairs of the partition per node", [prom(f'avg(count by (node) (kube_pod_info{{{CP}}}))', "mean"),
                                         prom(f'max(count by (node) (kube_pod_info{{{CP}}}))', "max")], w=12)
c.ts("Workers nodes: requested / allocatable (mean)", [
    *[prom(f'avg((sum by (node) (kube_pod_container_resource_requests{{resource="{res}"}}) / on (node) kube_node_status_allocatable{{resource="{res}"}}){workers})', res)
      for res in ["cpu", "memory"]],
    prom(f'avg((sum by (node) (kube_pod_info) / on (node) kube_node_status_allocatable{{resource="pods"}}){workers})', "pods / max pods")],
     w=12, unit="percentunit", description="What packs the nodes: the highest line is the binding resource")
c.ts("Workers nodes: used / allocatable (max node)", [
    prom(f'max((sum by (node) (rate(container_cpu_usage_seconds_total{{container!=""}}[1m])) / on (node) kube_node_status_allocatable{{resource="cpu"}}){workers})', "cpu"),
    prom(f'max((sum by (node) (container_memory_working_set_bytes{{container!=""}}) / on (node) kube_node_status_allocatable{{resource="memory"}}){workers})', "memory")],
     w=12, unit="percentunit",
     description="CPU near 100%: the node is saturated, the pairs wait for CPU without being throttled (requests below the use)")

c.row("Control plane")
# One query per RPC: rate() over several metric names drops the name, and their series then collide
RPCS = ["GrpcTasksService_SubmitTasks", "GrpcResultsService_CreateResultsMetaData", "GrpcResultsService_CreateResults",
        "GrpcResultsService_UploadResultData", "GrpcResultsService_DownloadResultData", "GrpcEventsService_GetEvents",
        "GrpcSessionsService_CreateSession", "GrpcTasksService_ListTasks", "GrpcTasksService_CountTasksByStatus"]
c.ts("RPC per second", [prom(f'sum(rate({m}_Count_total{{namespace="{NS}"}}[1m]))', m.split("_", 1)[1])
                        for m in RPCS], w=12, unit="reqps")
c.ts("RPC latency p95 (ms)", [prom(
    f'histogram_quantile(0.95, sum by (le) (rate({m}_milliseconds_bucket{{namespace="{NS}"}}[1m])))', m)
    for m in ["GrpcTasksService_SubmitTasks", "GrpcResultsService_CreateResultsMetaData",
              "GrpcResultsService_UploadResultData", "GrpcResultsService_DownloadResultData",
              "GrpcEventsService_GetEvents"]], w=12, unit="ms")
# Both control plane Deployments: the main one and the events one (GetEvents on the writer)
CPS = f'namespace="{NS}",pod=~"armonik-control-plane-.+",container="control-plane"'
c.ts("Control plane CPU per pod (m) vs limit", [
    prom(f'1000 * sum by (pod) (rate(container_cpu_usage_seconds_total{{{CPS}}}[1m]))', "{{pod}}"),
    prom(f'1000 * max(kube_pod_container_resource_limits{{{CPS},resource="cpu"}})', "limit"),
    prom(f'1000 * max(kube_pod_container_resource_requests{{{CPS},resource="cpu"}})', "request")],
     w=8, description="Main and events Deployments. One pod near the limit while the others idle: clients unevenly "
                      "spread over the replicas")
c.ts("Control plane CPU throttling", [prom(
    f'sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{{{CPS}}}[1m])) / sum by (pod) (rate(container_cpu_cfs_periods_total{{{CPS}}}[1m]))',
    "{{pod}}")], w=8, unit="percentunit", description="Share of the CFS periods where the pod hit its CPU limit")
c.ts("SubmitTasks and DownloadResultData per control plane pod", [
    prom(f'sum by (pod) (rate({m}_Count_total{{namespace="{NS}",pod=~"armonik-control-plane-.+"}}[1m]))',
         f'{m.rsplit("_", 1)[1]} {{{{pod}}}}') for m in ["GrpcTasksService_SubmitTasks", "GrpcResultsService_DownloadResultData"]],
     w=8, unit="reqps", description="Balanced through the ingress (per request), unbalanced with clients on the Service (per connection)")
ING = f'namespace="{NS}",pod=~"armonik-ingress-[0-9a-f]+-.+",container="ingress"'
c.ts("Ingress CPU per pod (m) vs limit", [
    prom(f'1000 * sum by (pod) (rate(container_cpu_usage_seconds_total{{{ING}}}[1m]))', "{{pod}}"),
    prom(f'1000 * max(kube_pod_container_resource_limits{{{ING},resource="cpu"}})', "limit")],
     w=12, description="nginx, every client request goes through it")
c.ts("Ingress CPU throttling", [prom(
    f'sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{{{ING}}}[1m])) / sum by (pod) (rate(container_cpu_cfs_periods_total{{{ING}}}[1m]))',
    "{{pod}}")], w=12, unit="percentunit")
c.ts("Control plane memory (MiB)", [
    prom(f'sum by (pod) (container_memory_working_set_bytes{{{CPS}}}) / 1048576', "{{pod}}")], w=24)

# ---------------------------------------------------------------------------------------------------------------------
# 2. PostgreSQL: Aurora (serverless scaling, instance, billed I/O), RDS Proxy, the engine and the statements
# ---------------------------------------------------------------------------------------------------------------------
p = Board("armonik-bench-postgresql", "Bench - PostgreSQL (Aurora, RDS Proxy)",
          "Aurora writer and RDS Proxy (CloudWatch, 1 point per minute), engine statistics and statements "
          "(postgres_exporter, every 15 s).")
p.row("Serverless v2 capacity (CloudWatch)")
p.ts("Capacity (ACU)", [rds("ServerlessDatabaseCapacity", "Average", "ACU mean"),
                        rds("ServerlessDatabaseCapacity", "Maximum", "ACU max")], w=12, description=ACU_HELP)
p.ts("Capacity vs completed tasks", [rds("ServerlessDatabaseCapacity", "Average", "ACU"),
                                     prom("sum(armonik:tasks_ended:rate1m)", "completed tasks/s")],
     ds=MIXED, w=12, overrides={"completed tasks/s": {"unit": "reqps", "custom.axisPlacement": "right"}},
     description="How fast the capacity follows a burst, and how far it falls after it (the buffer pool with it)")
p.ts("ACU utilization", [rds("ACUUtilization", "Average", "ACU / max ACU")], w=8, unit="percent",
     description="Capacity used over max_capacity: near 100 % the instance is capped, the scaling cannot help")
p.ts("Freeable memory", [rds("FreeableMemory", "Average", "freeable")], w=8, unit="bytes",
     description="Grows and shrinks with the ACUs on serverless")
p.ts("Buffer cache hit ratio", [rds("BufferCacheHitRatio", "Average", "hit ratio")], w=8, unit="percent",
     description="Drops after a scale-down: the pages of tasks and results come back from the storage")

p.row("Writer instance (CloudWatch)")
p.ts("CPU utilization", [rds("CPUUtilization", "Average", "mean"), rds("CPUUtilization", "Maximum", "max")],
     unit="percent", field=PERCENT_THRESHOLDS,
     description="On serverless, a share of the current capacity: high CPU at low ACU only means a scale-up is due")
p.ts("Database load (average active sessions)", [rds("DBLoad", label="total"), rds("DBLoadCPU", label="CPU"),
                                                 rds("DBLoadNonCPU", label="waits")],
     description="Performance Insights in CloudWatch. Above the vCPUs: sessions queue for the CPU. Waits: locks, I/O, "
                 "commits (details by wait event in the Performance Insights console)")
p.ts("Connections", [rds("DatabaseConnections", label="server connections")],
     description="Every connection of the writer: RDS Proxy, the GetEvents streams, the monitoring")
p.ts("Commits", [rds("CommitThroughput", label="commits/s")], unit="reqps", w=6)
p.ts("Commit latency", [rds("CommitLatency", label="mean")], unit="ms", w=6,
     description="Aurora commits on 4 of 6 copies of the storage, in 3 zones")
p.ts("Instance I/O", [rds("ReadIOPS", label="read IOPS"), rds("WriteIOPS", label="write IOPS")], unit="iops", w=6)
p.ts("I/O latency", [rds("ReadLatency", label="read"), rds("WriteLatency", label="write")], unit="s", w=6)

p.row("Storage: billed I/O and WAL (CloudWatch)")
p.ts("Billed I/O per 5 min", [volume("VolumeReadIOPs", "Sum", "read I/O", period=300),
                              volume("VolumeWriteIOPs", "Sum", "write I/O", period=300)], w=8,
     description="Billed per million on Standard storage, free on I/O-Optimized: Standard is cheaper while the I/O "
                 "stay under about a quarter of the bill. Points every 5 minutes")
p.ts("Volume used", [volume("VolumeBytesUsed", "Average", "bytes")], w=8, unit="bytes")
p.ts("WAL generated and kept for replication", [
    rds("TransactionLogsGeneration", label="WAL generated/s"),
    rds("ReplicationSlotDiskUsage", label="WAL kept by the slots"),
    rds("OldestReplicationSlotLag", label="oldest slot lag")], w=8, unit="bytes",
     overrides={"WAL generated/s": {"unit": "Bps"}},
     description="The logical replication slots of GetEvents: a growing lag keeps WAL on the volume")

p.row("RDS Proxy (CloudWatch)")
p.ts("Client and server connections", [
    proxy("ClientConnections", label="client connections (Core)"),
    proxy("DatabaseConnections", label="server connections"),
    proxy("DatabaseConnectionsCurrentlyBorrowed", label="borrowed (in use)"),
    proxy("MaxDatabaseConnectionsAllowed", label="max server connections")], w=12,
     description="Borrowed at the max: the clients queue for a server connection (borrow latency). Max follows "
                 "max_connections, which serverless derives from max_capacity")
p.ts("Pinned server connections", [proxy("DatabaseConnectionsCurrentlySessionPinned", label="pinned"),
                                   proxy("DatabaseConnectionsCurrentlyInTransaction", label="in transaction")], w=12,
     description="Pinned: a server connection kept by one client until it disconnects (prepared statements, SET, "
                 "advisory locks), no longer shared. Must stay near 0, or the proxy is no pooler")
p.ts("Borrow latency", [proxy("DatabaseConnectionsBorrowLatency", label="mean"),
                        proxy("DatabaseConnectionsBorrowLatency", "p99", label="p99")], w=8, unit="µs",
     description="Time a client waits for a server connection of the pool")
p.ts("Query latency through the proxy", [proxy("QueryDatabaseResponseLatency", label="database response"),
                                         proxy("QueryResponseLatency", label="proxy response")], w=8, unit="µs",
     description="Proxy response minus database response: what the proxy adds to a query")
p.ts("Queries and connection errors", [
    proxy("QueryRequests", "Sum", "queries/s", per_second=True),
    proxy("ClientConnectionsSetupFailedAuth", "Sum", "client auth failures/s", per_second=True),
    proxy("DatabaseConnectionsSetupFailed", "Sum", "server connection failures/s", per_second=True)], w=8, unit="reqps")

p.row("Engine (postgres_exporter)")
db = 'datname="__DATABASE__"'
p.ts("Transactions/s", [prom(f'sum(rate(pg_stat_database_xact_commit{{{db}}}[1m]))', "commit"),
                        prom(f'sum(rate(pg_stat_database_xact_rollback{{{db}}}[1m]))', "rollback")], unit="reqps")
p.ts("WAL generated", [prom("rate(pg_armonik_wal_wal_bytes[1m])", "bytes/s")], unit="Bps")
p.ts("Dead rows by table", [prom(f'topk(8, sum by (relname) (pg_stat_user_tables_n_dead_tup{{{db}}}))', "{{relname}}")])
p.ts("Autovacuum runs (5 min)", [prom(f'topk(8, sum by (relname) (increase(pg_stat_user_tables_autovacuum_count{{{db}}}[5m])))',
                                      "{{relname}}")], w=12)

p.row("ArmoniK specifics")
p.ts("Logical replication slot lag (WAL broadcaster)", [prom("pg_armonik_replication_slots_lag_bytes", "{{slot_name}}")],
     unit="bytes", w=12, description="WAL written but not yet confirmed by the WAL broadcaster of Core: must stay flat")
p.ts("Connections by application and state", [prom("sum by (application, state) (pg_armonik_connections_count)",
                                                    "{{application}} {{state}}")], w=12,
     description="Seen from the writer: the clients of the proxy show as the proxy's server connections")
p.ts("Connections waiting, by wait event type", [prom('sum by (wait_event_type) (pg_armonik_connections_count{wait_event_type!="none"})',
                                                      "{{wait_event_type}}")], w=8)
p.ts("Unfinished tasks by status", [prom("sum by (status) (pg_armonik_tasks_count)", "{{status}}")], w=8)
p.ts("Dependency backlog", [prom("pg_armonik_dependencies_remaining", "remaining dependencies"),
                            prom("pg_armonik_dependencies_dependent", "dependency edges")], w=8)

p.row("Statements (pg_stat_statements)")
p.panel("table", "Top statements by total time (range)", PROM, [prom(
    'topk(15, sum by (queryid) (increase(pg_stat_statements_seconds_total[$__range]))) * on (queryid) group_left (query) max by (queryid, query) (pg_stat_statements_query_id)',
    instant=True)],
        w=24, h=10, unit="s", options={"sortBy": [{"displayName": "Value", "desc": True}]})
p.ts("Top statements: time per second", [prom(
    'topk(8, sum by (queryid) (rate(pg_stat_statements_seconds_total[1m]))) * on (queryid) group_left (query) max by (queryid, query) (pg_stat_statements_query_id)', "{{query}}")], w=12, unit="s",
     description="Seconds of execution per second: the share of the database each statement takes")
p.ts("Top statements: calls per second", [prom(
    'topk(8, sum by (queryid) (rate(pg_stat_statements_calls_total[1m]))) * on (queryid) group_left (query) max by (queryid, query) (pg_stat_statements_query_id)', "{{query}}")], w=12, unit="reqps")

# ---------------------------------------------------------------------------------------------------------------------
# 3. Tasks: SQL on the tables of Core, over the time range (run analysis)
# ---------------------------------------------------------------------------------------------------------------------
t = Board("armonik-bench-tasks", "Bench - tasks (SQL, after a run)",
          "SQL on the tasks table over the selected range: throughput, lifecycle phases, statuses, dependencies. "
          "Load on the measured database: open it between steps, no automatic refresh.", refresh="")
# Tasks ending in the range were created at most this long before it: bounds the index scan on creation_date (no
# index on end_date), so that a panel reads the tasks of the range, not the whole table
t.templating.append({"name": "lookback", "label": "Max task lifetime", "type": "custom",
                     "query": "15 minutes,30 minutes,1 hour,6 hours", "current": {"text": "30 minutes", "value": "30 minutes"},
                     "options": [{"text": v, "value": v, "selected": v == "30 minutes"}
                                 for v in ["15 minutes", "30 minutes", "1 hour", "6 hours"]]})
t.templating.append({"name": "partition", "label": "Partition", "type": "query", "datasource": PG, "multi": True,
                     "includeAll": True, "query": "SELECT partition_id FROM partitions ORDER BY 1",
                     "refresh": 2, "current": {}})
RANGE = ("$__timeFilter(end_date) AND creation_date BETWEEN $__timeFrom()::timestamp - interval '$lookback' "
         "AND $__timeTo()::timestamp AND options_partition_id IN ($partition)")
CREATED = "$__timeFilter(creation_date) AND options_partition_id IN ($partition)"
ms = "extract(epoch from {b} - {a}) * 1000"
phases = [("submission", "creation_date", "submitted_date"), ("queue wait", "submitted_date", "reception_date"),
          ("acquisition", "reception_date", "acquisition_date"), ("data fetch", "acquisition_date", "fetched_date"),
          ("wait for worker", "fetched_date", "start_date"), ("execution", "start_date", "processed_date"),
          ("post-processing", "processed_date", "end_date")]

t.row("Throughput")
t.ts("Completed tasks per second (10 s buckets)", [sql(
    f"SELECT $__timeGroupAlias(end_date, '10s', 0), options_partition_id AS metric, count(*) / 10.0 AS value "
    f"FROM tasks WHERE status = 4 AND {RANGE} GROUP BY 1, 2 ORDER BY 1")], ds=PG, w=12, unit="reqps")
t.ts("Created tasks per second (10 s buckets)", [sql(
    f"SELECT $__timeGroupAlias(creation_date, '10s', 0), options_partition_id AS metric, count(*) / 10.0 AS value "
    f"FROM tasks WHERE {CREATED} GROUP BY 1, 2 ORDER BY 1")], ds=PG, w=12, unit="reqps")

t.row("Lifecycle phases (ended tasks)")
for q, label in [(0.5, "median"), (0.95, "p95")]:
    cols = ", ".join(f"percentile_cont({q}) WITHIN GROUP (ORDER BY {ms.format(a=a, b=b)}) AS \"{name}\""
                     for name, a, b in phases)
    t.ts(f"Phase duration {label} (ms, 30 s buckets)", [sql(
        f"SELECT $__timeGroupAlias(end_date, '30s'), {cols} FROM tasks WHERE status = 4 AND {RANGE} GROUP BY 1 ORDER BY 1")],
         ds=PG, w=12, unit="ms")
# Two tasks in a row on the same pod: what the worker waits between them, and how much of it is before the next
# message was even received (the SQS receive not hidden behind the previous task; negative = it came earlier)
GAPS = ("SELECT end_date, start_date, reception_date, lag(processed_date) OVER (PARTITION BY owner_pod_id "
        f"ORDER BY start_date) AS prev_processed FROM tasks WHERE status = 4 AND {RANGE}")
t.ts("Agent gap between two tasks (ms, 30 s buckets)", [sql(
    f"SELECT $__timeGroupAlias(end_date, '30s'), "
    f"avg({ms.format(a='prev_processed', b='start_date')}) AS \"worker idle, mean\", "
    f"percentile_cont(0.95) WITHIN GROUP (ORDER BY {ms.format(a='prev_processed', b='start_date')}) AS \"worker idle p95\", "
    f"percentile_cont(0.5) WITHIN GROUP (ORDER BY {ms.format(a='prev_processed', b='reception_date')}) AS \"receive wait median\", "
    f"percentile_cont(0.95) WITHIN GROUP (ORDER BY {ms.format(a='prev_processed', b='reception_date')}) AS \"receive wait p95\" "
    f"FROM ({GAPS}) g WHERE prev_processed IS NOT NULL GROUP BY 1 ORDER BY 1")], ds=PG, w=16, unit="ms")
t.ts("Next message received after the worker was free (share of tasks)", [sql(
    f"SELECT $__timeGroupAlias(end_date, '30s'), avg((reception_date > prev_processed)::int) AS \"receive late\" "
    f"FROM ({GAPS}) g WHERE prev_processed IS NOT NULL GROUP BY 1 ORDER BY 1")], ds=PG, w=8, unit="percentunit")
t.ts("End to end: creation to end (ms, 30 s buckets)", [sql(
    f"SELECT $__timeGroupAlias(end_date, '30s'), "
    f"percentile_cont(0.5) WITHIN GROUP (ORDER BY {ms.format(a='creation_date', b='end_date')}) AS median, "
    f"percentile_cont(0.95) WITHIN GROUP (ORDER BY {ms.format(a='creation_date', b='end_date')}) AS p95, "
    f"max({ms.format(a='creation_date', b='end_date')}) AS max "
    f"FROM tasks WHERE status = 4 AND {RANGE} GROUP BY 1 ORDER BY 1")], ds=PG, w=24, unit="ms")

t.row("Runs")
t.panel("table", "Sessions in range", PG, [sql(
    "SELECT session_id, options_partition_id AS partition, min(creation_date) AS first_created, max(end_date) AS last_end, "
    "count(*) AS tasks, count(*) FILTER (WHERE status = 4) AS completed, count(*) FILTER (WHERE status IN (5, 6)) AS failed, "
    "count(*) FILTER (WHERE cardinality(retry_of_ids) > 0) AS retries, "
    "count(*) FILTER (WHERE cardinality(data_dependencies) > 1) AS with_dependencies, "
    f"round(avg({ms.format(a='start_date', b='end_date')})::numeric) AS exec_ms_mean, "
    f"round((percentile_cont(0.95) WITHIN GROUP (ORDER BY {ms.format(a='start_date', b='end_date')}))::numeric) AS exec_ms_p95, "
    "round((count(*) FILTER (WHERE status = 4) / nullif(extract(epoch from max(end_date) - min(start_date)), 0))::numeric, 1) AS tasks_per_s "
    f"FROM tasks WHERE {CREATED} GROUP BY 1, 2 ORDER BY 3", fmt="table")], w=24, h=8)
t.panel("barchart", "Tasks by status (created in range)", PG, [sql(
    "SELECT CASE status WHEN 0 THEN 'Unspecified' WHEN 1 THEN 'Creating' WHEN 2 THEN 'Submitted' WHEN 3 THEN 'Dispatched' "
    "WHEN 4 THEN 'Completed' WHEN 5 THEN 'Error' WHEN 6 THEN 'Timeout' WHEN 7 THEN 'Cancelling' WHEN 8 THEN 'Cancelled' "
    "WHEN 9 THEN 'Processing' WHEN 10 THEN 'Processed' WHEN 11 THEN 'Retried' WHEN 12 THEN 'Pending' WHEN 13 THEN 'Paused' "
    f"ELSE status::text END AS status, count(*) AS tasks FROM tasks WHERE {CREATED} GROUP BY 1 ORDER BY 2 DESC",
    fmt="table")], w=12, h=8)
t.panel("barchart", "Data dependencies per task (created in range)", PG, [sql(
    "SELECT cardinality(data_dependencies)::text AS dependencies, count(*) AS tasks FROM tasks "
    f"WHERE {CREATED} GROUP BY cardinality(data_dependencies) ORDER BY cardinality(data_dependencies)", fmt="table")],
        w=12, h=8, description="1 is the payload alone: an independent task")

# ---------------------------------------------------------------------------------------------------------------------
# 4. Queue and object storage: SQS and S3, the managed services of the task flow (CloudWatch)
# ---------------------------------------------------------------------------------------------------------------------
q = Board("armonik-bench-sqs-s3", "Bench - SQS and S3",
          "SQS queues of the partitions and S3 bucket of the payloads and results (CloudWatch: 1 point per minute, "
          "a few minutes late).")
q.row("SQS: flow")
q.ts("Sent messages/s by queue", [sqs("NumberOfMessagesSent", per_second=True)], w=8, unit="reqps",
     description="Tasks submitted to the queue (one message per task, SendMessageBatch of up to 10)")
q.ts("Received and deleted messages/s", [
    sqs("NumberOfMessagesReceived", label="received", per_second=True, total=True),
    sqs("NumberOfMessagesDeleted", label="deleted", per_second=True, total=True)], w=8, unit="reqps",
     description="Deleted is the acknowledgement of a task. Received above deleted: messages released (visibility 0) or "
                 "received again after their visibility timeout (duplicate task)")
q.ts("Empty receives/s", [sqs("NumberOfEmptyReceives", per_second=True)], w=8, unit="reqps",
     description="Long polls that returned nothing: grows with the idle agents, not the tasks. Each one is a billed "
                 "request")

q.row("SQS: backlog")
q.ts("Visible messages (backlog)", [sqs("ApproximateNumberOfMessagesVisible", "Maximum")], w=8,
     description="Queued tasks not yet received by an agent")
q.ts("In flight (received, not deleted)", [sqs("ApproximateNumberOfMessagesNotVisible", "Maximum")], w=8,
     description="Tasks held by an agent. A standard queue holds at most 120,000 in flight: beyond, ReceiveMessage "
                 "fails with OverLimit")
q.ts("Oldest message age", [sqs("ApproximateAgeOfOldestMessage", "Maximum")], w=8, unit="s",
     description="Grows steadily: the agents do not keep up with the submission")

q.row("S3: requests (request metrics, EntireBucket)")
q.ts("Requests/s by type", [s3(m, label=m.replace("Requests", ""), per_second=True)
                            for m in ["PutRequests", "GetRequests", "HeadRequests", "DeleteRequests", "ListRequests"]],
     w=12, unit="reqps",
     description="S3 serves 3,500 writes and 5,500 reads per second per prefix partition, and splits a busy prefix "
                 "over time: Core keys are objectStorageName<UUIDv4>, random after the constant part, so they split")
q.ts("Writes/s vs tasks/s", [s3("PutRequests", label="S3 PUT/s", per_second=True),
                             sqs("NumberOfMessagesSent", label="tasks sent/s", per_second=True, total=True)],
     w=12, unit="reqps", description="About 2 writes per task: its payload and its result")
q.ts("Errors/s", [s3("4xxErrors", label="4xx", per_second=True), s3("5xxErrors", label="5xx", per_second=True)],
     w=8, unit="reqps",
     description="5xx: mostly 503 SlowDown while S3 splits a prefix (the warm-up of a new bucket, like GCS). 4xx: "
                 "reads of missing objects, denied access")
q.ts("Latency", [s3("FirstByteLatency", "p50", "first byte p50"), s3("FirstByteLatency", "p99", "first byte p99"),
                 s3("TotalRequestLatency", "p50", "total p50"), s3("TotalRequestLatency", "p99", "total p99")],
     w=8, unit="ms", description="Measured by S3, without the network to the client")
q.ts("Bytes/s", [s3("BytesUploaded", label="uploaded", per_second=True),
                 s3("BytesDownloaded", label="downloaded", per_second=True)], w=8, unit="Bps")

# ---------------------------------------------------------------------------------------------------------------------
# 0. Run: the one screen to watch during a campaign, top-down along the saturation criterion: does the completion
#    follow the target, does the queue stay flat, and if not, which component is the limit
# ---------------------------------------------------------------------------------------------------------------------
r = Board("armonik-bench-run", "Bench - run",
          "During a campaign: throughput against the target, the queue, the agents, then the platform (Aurora, RDS "
          "Proxy, SQS, S3, control plane). Details in the other Bench dashboards.")
r.templating.append(dict(c.templating[0], current={"text": "htcmock", "value": "htcmock"}))
submitted = f'sum(rate(GrpcTasksService_SubmitTasks_Count_total{{namespace="{NS}"}}[1m])) * 100'
queue = 'sum({__name__="armonik_${partition}_tasks_queued"}) + sum({__name__="armonik_${partition}_tasks_dispatched"})'
busy = f'sum({{__name__="armonik_${{partition}}_tasks_processing"}}) / {pods}'
agent, worker = 'partition="$partition",container="agent"', 'partition="$partition",container="worker"'

r.stat("Completed/s", [prom("sum(armonik:tasks_ended:rate1m)")], w=3, unit="reqps",
       description="Ends of tasks, all partitions (only the campaign's runs)")
r.stat("Submitted/s", [prom(submitted)], w=3, unit="reqps",
       description="SubmitTasks calls x 100, the batch of the Bench client")
r.stat("Queue", [prom(queue)], w=3, description="Submitted and dispatched tasks of the partition")
r.stat("Busy ratio", [prom(busy)], w=3, unit="percentunit")
r.stat("Ready pods", [prom(pods)], w=3)
r.stat("Database CPU", [rds("CPUUtilization", label="CPU")], ds=CW, w=3, unit="percent", field=PERCENT_THRESHOLDS)
r.stat("Database ACU", [rds("ServerlessDatabaseCapacity", label="ACU")], ds=CW, w=3, description=ACU_HELP)
r.stat("Workers nodes (spot)", [prom('count(kube_node_labels{label_karpenter_sh_nodepool="workers",label_karpenter_sh_capacity_type="spot"}) or vector(0)')],
       w=3, description="A drop during a step: spot interruptions, the step is not valid")

r.row("Throughput")
r.ts("Submitted and completed", [prom("sum(armonik:tasks_ended:rate1m)", "completed/s"), prom(submitted, "submitted/s")],
     w=16, unit="reqps", description="A step holds when the completions reach 95 % of its target (workers / task duration)")
r.ts("Completed per pod and busy ratio", [prom(f"sum(armonik:tasks_ended:rate1m) / {pods}", "tasks/s per pod"),
                                          prom(busy, "busy ratio")], w=8,
     overrides={"busy ratio": {"unit": "percentunit", "custom.axisPlacement": "right"}})

r.row("Queue")
r.ts("Tasks of the partition", [prom('sum({__name__="armonik_${partition}_tasks_queued"})', "queued"),
                                prom('sum({__name__="armonik_${partition}_tasks_dispatched"})', "dispatched"),
                                prom('sum({__name__="armonik_${partition}_tasks_processing"})', "processing")], w=8,
     description="Queued growing through a step: the platform does not keep up")
r.ts("SQS: visible and in flight", [sqs("ApproximateNumberOfMessagesVisible", "Maximum", "visible", total=True),
                                    sqs("ApproximateNumberOfMessagesNotVisible", "Maximum", "in flight", total=True)],
     ds=CW, w=8, description="CloudWatch: a few minutes late")
r.ts("SQS: oldest message", [sqs("ApproximateAgeOfOldestMessage", "Maximum")], ds=CW, w=8, unit="s")

r.row("Agents and workers")
r.ts("Agent CPU (m)", [prom(f"quantile(0.5, armonik:container_cpu_millicores:rate1m{{{agent}}})", "median"),
                       prom(f"quantile(0.95, armonik:container_cpu_millicores:rate1m{{{agent}}})", "p95"),
                       prom(f'1000 * avg(kube_pod_container_resource_requests{{{CP},container="agent",resource="cpu"}})', "request")],
     w=8, description="p95 above the request: the nodes are packed beyond what the pairs use")
r.ts("Agent memory (MiB)", [prom(f"max(armonik:container_memory_working_set_mib{{{agent}}})", "max"),
                            prom(f'avg(kube_pod_container_resource_limits{{{CP},container="agent",resource="memory"}}) / 1048576', "limit")],
     w=8, description="A max climbing over a long step: a leak")
r.ts("Worker memory (MiB)", [prom(f"max(armonik:container_memory_working_set_mib{{{worker}}})", "max"),
                             prom(f'avg(kube_pod_init_container_resource_limits{{{CP},container="worker",resource="memory"}}) / 1048576', "limit")],
     w=8)

r.row("Task phases (polling agent)")
phase = 'armonik:task_phase_milliseconds_%s:rate1m{partition="$partition"}'
r.ts("Mean duration per phase (ms per task)", [prom(f"{phase % 'sum'} / {phase % 'count'}", "{{phase}}")], w=12,
     unit="ms", description="Recording rules of the bench-monitoring chart. RequestExecution is the worker's part of "
                            "ExecuteTask. PostProcessing: results and subtasks created, task ended in the database. "
                            "DisposeAsync: task released, message deleted")
post = 'armonik:task_phase_milliseconds_bucket:rate1m{partition="$partition",phase="PostProcessing"}'
r.ts("PostProcessing latency (ms)", [prom(f"histogram_quantile({x}, sum by (le) ({post}))", label)
                                     for x, label in [(0.5, "p50"), (0.95, "p95"), (0.99, "p99")]], w=12, unit="ms",
     description="Interpolated in the default buckets of Core (5, 10, 25, 50, 75, 100, 250, 500, 750 ms, 1 s...): "
                 "coarse between two bounds. Exact values per task in Bench - tasks (SQL)")
for name, title, desc in [
    ("DisposeAsync", "SQS delete: DisposeAsync latency (ms)",
     "The task released, then its message deleted (QueueMessageHandler.DisposeAsync): the only measure of the "
     "acknowledgement inside the agent. Runs in the post-processing stage, after end_date: it slows the agent only "
     "when post-processing plus delete outlast the next task's execution"),
    ("AcquireTask", "AcquireTask latency (ms)",
     "From the received message to the task acquired in the database. The SQS receive itself is before it and has "
     "no metric: see the agent gap in Bench - tasks (SQL)")]:
    sel = f'armonik:task_phase_milliseconds_bucket:rate1m{{partition="$partition",phase="{name}"}}'
    r.ts(title, [prom(f"histogram_quantile({x}, sum by (le) ({sel}))", label)
                 for x, label in [(0.5, "p50"), (0.95, "p95"), (0.99, "p99")]], w=12, unit="ms", description=desc)

r.row("Database")
r.ts("Aurora CPU and capacity", [rds("CPUUtilization", label="CPU %"), rds("ServerlessDatabaseCapacity", label="ACU")],
     ds=CW, w=8, unit="percent", overrides={"ACU": {"unit": "none", "custom.axisPlacement": "right"}},
     description="Provisioned: sized for 70 % CPU at the target rate. Serverless: the ACU follow the load")
r.ts("RDS Proxy: borrowed connections and borrow latency", [
    proxy("DatabaseConnectionsCurrentlyBorrowed", label="borrowed"),
    proxy("DatabaseConnectionsBorrowLatency", label="borrow latency")], ds=CW, w=8,
     overrides={"borrow latency": {"unit": "µs", "custom.axisPlacement": "right"}})
r.ts("Replication slot lag (WAL broadcaster)", [prom("max(pg_armonik_replication_slots_lag_bytes)", "lag")], w=8,
     unit="bytes", description="Must stay flat: a growing lag keeps WAL on the volume")
r.ts("Top statements: time per second", [prom(
    'topk(8, sum by (queryid) (rate(pg_stat_statements_seconds_total[1m]))) * on (queryid) group_left (query) max by (queryid, query) (pg_stat_statements_query_id)',
    "{{query}}")], w=24, h=9, unit="s",
     description="Seconds of execution per second, i.e. cores of the database per statement. The liveness check of "
                 "Core grows with the pods, not the tasks")

r.row("Object storage and control plane")
r.ts("S3 writes/s vs tasks/s", [s3("PutRequests", label="S3 PUT/s", per_second=True),
                                sqs("NumberOfMessagesSent", label="tasks sent/s", per_second=True, total=True)],
     w=8, unit="reqps", description="About 2 writes per task: its payload and its result")
r.ts("S3 errors/s", [s3("5xxErrors", label="5xx (SlowDown)", per_second=True),
                     s3("4xxErrors", label="4xx", per_second=True)], ds=CW, w=8, unit="reqps",
     description="503 SlowDown: S3 splits a prefix under the load, the warm-up of the bucket")
r.ts("SubmitTasks latency p95 (ms)", [prom(
    f'histogram_quantile(0.95, sum by (le) (rate(GrpcTasksService_SubmitTasks_milliseconds_bucket{{namespace="{NS}"}}[1m])))',
    "p95")], w=8, unit="ms")
r.ts("Control plane CPU per pod (m) vs limit", [
    prom(f'1000 * sum by (pod) (rate(container_cpu_usage_seconds_total{{{CPS}}}[1m]))', "{{pod}}"),
    prom(f'1000 * max(kube_pod_container_resource_limits{{{CPS},resource="cpu"}})', "limit")], w=12)
r.ts("Control plane CPU throttling", [prom(
    f'sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{{{CPS}}}[1m])) / sum by (pod) (rate(container_cpu_cfs_periods_total{{{CPS}}}[1m]))',
    "{{pod}}")], w=12, unit="percentunit")

r.row("Health")
r.ts("Nodes by Karpenter pool, instance type and capacity type", [prom(*NODES)], w=8)
r.ts("Restarts by container", [prom(f'sum by (container) (increase(kube_pod_container_status_restarts_total{{{CP}}}[5m]))')],
     w=8)
r.ts("Prometheus", [prom("prometheus_tsdb_head_series", "head series"),
                    prom('sum(container_memory_working_set_bytes{namespace="__OPERATORS_NAMESPACE__",pod=~"prometheus-kps-prometheus-.+",container="prometheus"})',
                         "memory")], w=8, overrides={"memory": {"unit": "bytes", "custom.axisPlacement": "right"}},
     description="Series in memory and the memory of Prometheus")

# ---------------------------------------------------------------------------------------------------------------------
# 5. Network: Cilium in ENI mode (flows seen by Hubble, datapath of the agents, IPs and ENIs of the operator)
# ---------------------------------------------------------------------------------------------------------------------
n = Board("armonik-bench-network", "Bench - network (Cilium)",
          "Flows seen by Hubble, datapath of the Cilium agents, pod IPs and ENIs of the operator, network of the nodes.")
AG = 'namespace="kube-system",container="cilium-agent"'
n.row("Flows (Hubble)")
n.ts("Flows/s by verdict", [prom('sum by (verdict) (rate(hubble_flows_processed_total[1m]))', "{{verdict}}")],
     w=8, unit="reqps", description="DROPPED or ERROR above zero: look at the drop reasons")
n.ts("Drops/s by reason", [prom('sum by (reason, protocol) (rate(hubble_drop_total[1m]))', "{{reason}} {{protocol}}")],
     w=8, unit="reqps", description="Policy denied, no route, CT map full, unknown connection...")
n.ts("TCP SYN and RST/s", [prom('sum by (flag) (rate(hubble_tcp_flags_total{flag=~"SYN|RST"}[1m]))', "{{flag}}")],
     w=8, unit="reqps",
     description="SYN: new connections, such as the agents opening database or S3 connections. RST: connections cut")
n.ts("DNS queries and failed answers/s", [
    prom('sum(rate(hubble_dns_queries_total[1m]))', "queries"),
    prom('sum by (rcode) (rate(hubble_dns_responses_total{rcode!="No Error"}[1m]))', "{{rcode}}")], w=12, unit="reqps",
     description="Every connection to AWS (SQS, S3, Aurora) starts with a lookup: a failure rate here is a CoreDNS limit")
n.ts("Top destination ports/s", [prom('topk(8, sum by (protocol, port) (rate(hubble_port_distribution_total[1m])))',
                                      "{{protocol}}/{{port}}")], w=12, unit="reqps")

n.row("Datapath (agents)")
n.ts("Forwarded bytes/s", [prom('sum by (direction) (rate(cilium_forward_bytes_total[1m]))', "{{direction}}")],
     w=8, unit="Bps")
n.ts("Datapath drops/s by reason", [prom('sum by (reason, direction) (rate(cilium_drop_count_total[1m]))',
                                         "{{reason}} {{direction}}")], w=8, unit="reqps")
n.ts("BPF map pressure (max node)", [prom('max by (map_name) (cilium_bpf_map_pressure)', "{{map_name}}")], w=8,
     unit="percentunit", description="Near 1: the map is full (connection tracking, NAT), new connections drop")
n.ts("Agent CPU per node (m)", [prom(f'1000 * sum by (pod) (rate(container_cpu_usage_seconds_total{{{AG}}}[1m]))', "{{pod}}")],
     w=12)
n.ts("Agent memory per node (MiB)", [prom(f'sum by (pod) (container_memory_working_set_bytes{{{AG}}}) / 1048576', "{{pod}}")],
     w=12)

n.row("Pod IPs and ENIs (operator)")
n.ts("Pod IPs of the cluster", [prom('sum by (type) (cilium_operator_ipam_ips)', "{{type}}")], w=8,
     description="needed above available: pods wait for the operator to attach an ENI or assign IPs to a node")
n.ts("EC2 API latency p95 by operation", [prom(
    'histogram_quantile(0.95, sum by (le, operation) (rate(cilium_operator_ec2_api_duration_seconds_bucket[5m])))',
    "{{operation}}")], w=8, unit="s",
     description="CreateNetworkInterface, AttachNetworkInterface, AssignPrivateIpAddresses: what a new node waits for")
n.ts("EC2 API calls/s and throttling", [
    prom('sum by (operation) (rate(cilium_operator_ec2_api_duration_seconds_count[5m]))', "{{operation}}"),
    prom('sum(rate(cilium_operator_ec2_api_rate_limit_duration_seconds_count[5m]))', "rate limited")], w=8,
     unit="reqps", description="The operator throttles itself below the EC2 quotas of the account")

n.row("Nodes (node-exporter)")
NIC = 'device=~"ens.*|eth.*"'
n.ts("Received bytes/s per node (top 10)", [prom(
    f'topk(10, sum by (instance) (rate(node_network_receive_bytes_total{{{NIC}}}[1m])))', "{{instance}}")], w=12, unit="Bps")
n.ts("Transmitted bytes/s per node (top 10)", [prom(
    f'topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{{{NIC}}}[1m])))', "{{instance}}")], w=12, unit="Bps")

for b, name in [(r, "bench-run"), (c, "bench-compute"), (p, "bench-postgresql"), (t, "bench-tasks"), (q, "bench-sqs-s3"),
                (n, "bench-network")]:
    (OUT / f"{name}.json").write_text(json.dumps(b.dump(), indent=2) + "\n")
    print(name, len(b.panels), "panels")

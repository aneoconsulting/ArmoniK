#!/usr/bin/env python3
"""Generates the bench dashboards (Grafana JSON) of monitoring/dashboards.

    python3 monitoring/gen-dashboards.py monitoring/dashboards
"""
import json
import sys
from pathlib import Path

OUT = Path(sys.argv[1])
PROM = {"type": "prometheus", "uid": "PBFA97CFB590B2093"}
GCM = {"type": "stackdriver", "uid": "cloud-monitoring"}
PG = {"type": "grafana-postgresql-datasource", "uid": "armonik-postgresql"}

CP = 'namespace="armonik",pod=~"armonik-compute-plane-$partition-[a-z0-9]+-[a-z0-9]+"'


class Board:
    def __init__(self, uid, title, description):
        self.uid, self.title, self.description = uid, title, description
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

    def panel(self, kind, title, ds, targets, w=8, h=8, unit=None, description=None, options=None, field=None):
        p = {"type": kind, "title": title, "id": self._id(), "datasource": ds, "gridPos": self._place(w, h),
             "targets": [dict(t, refId=chr(65 + i), datasource=ds) for i, t in enumerate(targets)],
             "fieldConfig": {"defaults": dict({"unit": unit} if unit else {}, **(field or {})), "overrides": []},
             "options": options or {}}
        if description:
            p["description"] = description
        self.panels.append(p)

    def ts(self, title, targets, **kw):
        kw.setdefault("options", {"legend": {"displayMode": "table", "placement": "bottom", "calcs": ["mean", "max"]},
                                  "tooltip": {"mode": "multi"}})
        self.panel("timeseries", title, kw.pop("ds", PROM), targets, **kw)

    def stat(self, title, targets, **kw):
        self.panel("stat", title, kw.pop("ds", PROM), targets, w=kw.pop("w", 4), h=kw.pop("h", 4), **kw)

    def dump(self):
        return {"uid": self.uid, "title": self.title, "description": self.description, "tags": ["armonik", "bench"],
                "timezone": "utc", "schemaVersion": 39, "editable": True, "refresh": "30s",
                "time": {"from": "now-1h", "to": "now"}, "templating": {"list": self.templating},
                "annotations": {"list": []}, "panels": self.panels}


def prom(expr, legend="__auto", instant=False):
    return {"expr": expr, "legendFormat": legend, "range": not instant, "instant": instant}


def gcm(metric, aligner="ALIGN_MEAN", reducer="REDUCE_NONE", group_bys=None):
    return {"queryType": "timeSeriesList", "timeSeriesList": {
        "projectName": "__PROJECT__",
        "filters": ["metric.type", "=", metric, "AND", "resource.labels.database_id", "=", "__CLOUDSQL_DATABASE_ID__"],
        "perSeriesAligner": aligner, "crossSeriesReducer": reducer, "groupBys": group_bys or [],
        "alignmentPeriod": "cloud-monitoring-auto", "view": "FULL"}}


def sql(query, fmt="time_series"):
    return {"rawSql": query, "format": fmt, "rawQuery": True, "editorMode": "code"}


# ---------------------------------------------------------------------------------------------------------------------
# 1. Compute plane: what an agent/worker pair costs, and how the nodes are filled
# ---------------------------------------------------------------------------------------------------------------------
c = Board("armonik-bench-compute", "Bench - compute (agent/worker)",
          "Cost of an agent/worker pair per partition and node packing. CPU in millicores (1 min rate).")
# From the Deployments, which exist at 0 pod too, so that the variable is never empty
c.templating.append({"name": "partition", "label": "Partition", "type": "query", "datasource": PROM,
                     "query": {"query": 'label_values(kube_deployment_spec_replicas{namespace="armonik",deployment=~"armonik-compute-plane-.+"}, deployment)',
                               "refId": "partition"},
                     "regex": "/armonik-compute-plane-(.+)/", "refresh": 2, "sort": 1, "current": {}})
pods = f'sum(kube_deployment_status_replicas_available{{namespace="armonik",deployment="armonik-compute-plane-$partition"}})'

c.row("Load")
c.stat("Pods", [prom(pods)])
c.stat("Busy pods", [prom('sum({__name__="armonik_${partition}_tasks_dispatched"})')],
       description="Tasks dispatched to a pod right now (Core metrics exporter)")
c.stat("Busy ratio", [prom(f'sum({{__name__="armonik_${{partition}}_tasks_dispatched"}}) / {pods}')], unit="percentunit")
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
    prom('sum(kube_node_status_allocatable{resource="cpu"} * on (node) group_left () (kube_node_labels{label_cloud_google_com_compute_class="workers"} > 0))',
         "workers nodes allocatable")],
     w=24, description="Used: what the pairs burn. Requested: what sizes the nodes. Allocatable: the vCPU of the workers nodes, what is paid")

for ct in ["agent", "worker"]:
    sel = f'partition="$partition",container="{ct}"'
    req = f'kube_pod_container_resource_requests{{{CP},container="{ct}",resource="%s"}}'
    lim = f'kube_pod_container_resource_limits{{{CP},container="{ct}",resource="%s"}}'
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
    c.ts(f"{ct} usage / request", [
        prom(f"sum(armonik:container_cpu_millicores:rate1m{{{sel}}}) / (1000 * sum({req % 'cpu'}))", "CPU"),
        prom(f"sum(armonik:container_memory_working_set_mib{{{sel}}}) / (sum({req % 'memory'}) / 1048576)",
             "memory"),
        prom(f"max(armonik:container_cpu_throttled_ratio:rate1m{{{sel}}})", "CPU throttled (max pod)")],
         unit="percentunit", description="Below 1: requests larger than the use. Throttled: periods capped by the limit")

c.row("Health")
c.stat("OOM killed containers", [prom(
    f'sum(kube_pod_container_status_last_terminated_reason{{{CP},reason="OOMKilled"}}) or vector(0)')])
c.stat("Restarts (range)", [prom(f'sum(increase(kube_pod_container_status_restarts_total{{{CP}}}[$__range])) or vector(0)',
                                 instant=True)])
c.ts("Restarts by container", [prom(f'sum by (container) (increase(kube_pod_container_status_restarts_total{{{CP}}}[5m]))')],
     w=16)

c.row("Nodes")
nl = 'kube_node_labels{label_cloud_google_com_compute_class!=""}'
c.ts("Nodes by ComputeClass, machine type and Spot", [prom(
    f"count by (label_cloud_google_com_compute_class, label_node_kubernetes_io_instance_type, label_cloud_google_com_gke_spot) ({nl})",
    "{{label_cloud_google_com_compute_class}} {{label_node_kubernetes_io_instance_type}} spot={{label_cloud_google_com_gke_spot}}")],
     w=12)
c.ts("Pairs of the partition per node", [prom(f'avg(count by (node) (kube_pod_info{{{CP}}}))', "mean"),
                                         prom(f'max(count by (node) (kube_pod_info{{{CP}}}))', "max")], w=12)
workers = ' * on (node) group_left () (kube_node_labels{label_cloud_google_com_compute_class="workers"} > 0)'
for res, unit in [("cpu", "percentunit"), ("memory", "percentunit")]:
    c.ts(f"Workers nodes: {res} requested / allocatable", [
        prom(f'avg((sum by (node) (kube_pod_container_resource_requests{{resource="{res}"}}) / on (node) kube_node_status_allocatable{{resource="{res}"}}){workers})', "mean"),
        prom(f'min((sum by (node) (kube_pod_container_resource_requests{{resource="{res}"}}) / on (node) kube_node_status_allocatable{{resource="{res}"}}){workers})', "min"),
        prom(f'avg((sum by (node) (kube_pod_info) / on (node) kube_node_status_allocatable{{resource="pods"}}){workers})', "pods / max pods")],
         w=12, unit=unit)

c.ts("Workers nodes: CPU used / allocatable", [
    prom(f'avg((sum by (node) (rate(container_cpu_usage_seconds_total{{container!=""}}[1m])) / on (node) kube_node_status_allocatable{{resource="cpu"}}){workers})', "mean"),
    prom(f'max((sum by (node) (rate(container_cpu_usage_seconds_total{{container!=""}}[1m])) / on (node) kube_node_status_allocatable{{resource="cpu"}}){workers})', "max")],
     w=12, unit="percentunit",
     description="Near 100%: the node is saturated, the pairs wait for CPU without being throttled (requests below the use)")
c.ts("Workers nodes: memory used / allocatable", [
    prom(f'avg((sum by (node) (container_memory_working_set_bytes{{container!=""}}) / on (node) kube_node_status_allocatable{{resource="memory"}}){workers})', "mean"),
    prom(f'max((sum by (node) (container_memory_working_set_bytes{{container!=""}}) / on (node) kube_node_status_allocatable{{resource="memory"}}){workers})', "max")],
     w=12, unit="percentunit")

c.row("Control plane")
# One query per RPC: rate() over several metric names drops the name, and their series then collide
RPCS = ["GrpcTasksService_SubmitTasks", "GrpcResultsService_CreateResultsMetaData", "GrpcResultsService_CreateResults",
        "GrpcResultsService_UploadResultData", "GrpcResultsService_DownloadResultData", "GrpcEventsService_GetEvents",
        "GrpcSessionsService_CreateSession", "GrpcTasksService_ListTasks", "GrpcTasksService_CountTasksByStatus"]
c.ts("RPC per second", [prom(f'sum(rate({m}_Count_total{{namespace="armonik"}}[1m]))', m.split("_", 1)[1])
                        for m in RPCS], w=12, unit="reqps")
c.ts("RPC latency p95 (ms)", [prom(
    f'histogram_quantile(0.95, sum by (le) (rate({m}_milliseconds_bucket{{namespace="armonik"}}[1m])))', m)
    for m in ["GrpcTasksService_SubmitTasks", "GrpcResultsService_CreateResultsMetaData",
              "GrpcResultsService_UploadResultData", "GrpcResultsService_DownloadResultData",
              "GrpcEventsService_GetEvents"]], w=12, unit="ms")
CPS = 'namespace="armonik",pod=~"armonik-control-plane-[0-9a-f]+-.+",container="control-plane"'
c.ts("Control plane CPU per pod (m) vs limit", [
    prom(f'1000 * sum by (pod) (rate(container_cpu_usage_seconds_total{{{CPS}}}[1m]))', "{{pod}}"),
    prom(f'1000 * max(kube_pod_container_resource_limits{{{CPS},resource="cpu"}})', "limit"),
    prom(f'1000 * max(kube_pod_container_resource_requests{{{CPS},resource="cpu"}})', "request")],
     w=8, description="One pod near the limit while the others idle: clients unevenly spread over the replicas")
c.ts("Control plane CPU throttling", [prom(
    f'sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{{{CPS}}}[1m])) / sum by (pod) (rate(container_cpu_cfs_periods_total{{{CPS}}}[1m]))',
    "{{pod}}")], w=8, unit="percentunit", description="Share of the CFS periods where the pod hit its CPU limit")
c.ts("SubmitTasks and DownloadResultData per control plane pod", [
    prom(f'sum by (pod) (rate({m}_Count_total{{namespace="armonik",pod=~"armonik-control-plane-[0-9a-f]+-.+"}}[1m]))',
         f'{m.rsplit("_", 1)[1]} {{{{pod}}}}') for m in ["GrpcTasksService_SubmitTasks", "GrpcResultsService_DownloadResultData"]],
     w=8, unit="reqps", description="Balanced through the ingress (per request), unbalanced with clients on the Service (per connection)")
ING = 'namespace="armonik",pod=~"armonik-ingress-[0-9a-f]+-.+",container="ingress"'
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
# 2. PostgreSQL: the Cloud SQL instance, the engine and the monitoring's own cost
# ---------------------------------------------------------------------------------------------------------------------
p = Board("armonik-bench-postgresql", "Bench - PostgreSQL (Cloud SQL)",
          "Cloud SQL instance (Cloud Monitoring), engine statistics (postgres_exporter) and the cost of the monitoring.")
p.row("Instance (Cloud Monitoring)")
p.ts("CPU utilization", [gcm("cloudsql.googleapis.com/database/cpu/utilization")], ds=GCM, unit="percentunit")
p.ts("Memory utilization", [gcm("cloudsql.googleapis.com/database/memory/utilization")], ds=GCM, unit="percentunit")
p.ts("Disk utilization", [gcm("cloudsql.googleapis.com/database/disk/utilization")], ds=GCM, unit="percentunit")
p.ts("Disk IOPS", [gcm("cloudsql.googleapis.com/database/disk/read_ops_count", "ALIGN_RATE"),
                   gcm("cloudsql.googleapis.com/database/disk/write_ops_count", "ALIGN_RATE")], ds=GCM, unit="iops")
p.ts("Disk throughput", [gcm("cloudsql.googleapis.com/database/disk/read_bytes_count", "ALIGN_RATE"),
                         gcm("cloudsql.googleapis.com/database/disk/write_bytes_count", "ALIGN_RATE")], ds=GCM,
     unit="Bps")
p.ts("Connections (backends)", [gcm("cloudsql.googleapis.com/database/postgresql/num_backends", "ALIGN_MEAN",
                                    "REDUCE_SUM")], ds=GCM)

p.row("Engine")
db = 'datname="armonik"'
p.ts("Transactions/s", [prom(f'sum(rate(pg_stat_database_xact_commit{{{db}}}[1m]))', "commit"),
                        prom(f'sum(rate(pg_stat_database_xact_rollback{{{db}}}[1m]))', "rollback")], unit="reqps")
p.ts("WAL generated", [prom("rate(pg_armonik_wal_wal_bytes[1m])", "bytes/s")], unit="Bps")
p.ts("Cache hit ratio", [prom(f'sum(rate(pg_stat_database_blks_hit{{{db}}}[1m])) / (sum(rate(pg_stat_database_blks_hit{{{db}}}[1m])) + sum(rate(pg_stat_database_blks_read{{{db}}}[1m])))', "hit")],
     unit="percentunit")
for col, title in [("n_tup_ins", "Rows inserted/s"), ("n_tup_upd", "Rows updated/s"), ("n_tup_del", "Rows deleted/s")]:
    p.ts(f"{title} by table", [prom(f'topk(8, sum by (relname) (rate(pg_stat_user_tables_{col}{{{db}}}[1m])))',
                                    "{{relname}}")], unit="reqps")
p.ts("Dead rows by table", [prom(f'topk(8, sum by (relname) (pg_stat_user_tables_n_dead_tup{{{db}}}))', "{{relname}}")])
p.ts("Autovacuum runs (5 min)", [prom(f'topk(8, sum by (relname) (increase(pg_stat_user_tables_autovacuum_count{{{db}}}[5m])))',
                                      "{{relname}}")])
p.ts("Locks by mode", [prom(f'sum by (mode) (pg_locks_count{{{db}}})', "{{mode}}")])

p.row("ArmoniK specifics")
p.ts("Logical replication slot lag (WAL broadcaster)", [prom("pg_armonik_replication_slots_lag_bytes", "{{slot_name}}")],
     unit="bytes", w=12, description="WAL written but not yet confirmed by the WAL broadcaster of Core: must stay flat")
p.ts("Connections by application and state", [prom("sum by (application, state) (pg_armonik_connections_count)",
                                                    "{{application}} {{state}}")], w=12)
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

p.row("Cost of the monitoring")
p.ts("postgres_exporter scrape duration", [prom("pg_exporter_last_scrape_duration_seconds", "scrape")], unit="s")
p.ts("Prometheus head series", [prom("prometheus_tsdb_head_series", "series")])
p.ts("Prometheus memory", [prom('sum(container_memory_working_set_bytes{namespace="operators",pod=~"prometheus-kps-prometheus-.+",container="prometheus"})',
                                "working set")], unit="bytes")

# ---------------------------------------------------------------------------------------------------------------------
# 3. Tasks: SQL on the tables of Core, over the time range (run analysis)
# ---------------------------------------------------------------------------------------------------------------------
t = Board("armonik-bench-tasks", "Bench - tasks (SQL)",
          "SQL on the tasks table over the selected range: throughput, lifecycle phases, statuses, dependencies. "
          "Runs only when displayed (load on the database).")
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
          ("wait for worker", "fetched_date", "start_date"), ("execution", "start_date", "end_date")]

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

OUT.mkdir(parents=True, exist_ok=True)
for b, name in [(c, "bench-compute"), (p, "bench-postgresql"), (t, "bench-tasks")]:
    (OUT / f"{name}.json").write_text(json.dumps(b.dump(), indent=2) + "\n")
    print(name, len(b.panels), "panels")

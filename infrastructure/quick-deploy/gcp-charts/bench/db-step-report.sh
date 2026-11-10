#!/usr/bin/env sh
# Summary of a database step over a UTC window: the numbers of the bench dashboards, as one table row.
#
#   bench/db-step-report.sh <start HH:MM:SS> <end HH:MM:SS> [date YYYY-MM-DD]
#
# Needs kubectl (Prometheus through the API server proxy) and gcloud (Cloud Monitoring, the Cloud SQL instance of
# the database module).
set -eu

DAY=${3:-$(date -u +%Y-%m-%d)}
START=$(date -u -d "$DAY $1" +%s) END=$(date -u -d "$DAY $2" +%s)
WINDOW=$(( (END - START) / 60 ))m
PROM=/api/v1/namespaces/operators/services/kps-prometheus:9090/proxy/api/v1/query

prom() {
  kubectl get --raw "$PROM?time=$END&query=$(printf %s "$1" | jq -sRr @uri)" |
    jq -r '.data.result[0].value[1] // "nan" | tonumber? // "nan" | if type == "number" then (. * 100 | round / 100) else . end'
}

# The project and the instance of the deployment: from the configuration of Core
PROJECT=$(kubectl -n armonik get secret armonik-conf-core -o jsonpath='{.data.PubSub__ProjectId}' | base64 -d)
INSTANCE=$(gcloud sql instances list --project "$PROJECT" --format='value(name)' --limit=1)
gcm() { # mean of a Cloud SQL metric over the window
  curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://monitoring.googleapis.com/v3/projects/$PROJECT/timeSeries" \
    --data-urlencode "filter=metric.type=\"cloudsql.googleapis.com/$1\" AND resource.labels.database_id=\"$PROJECT:$INSTANCE\"" \
    --data-urlencode "interval.startTime=$(date -u -d "@$START" +%Y-%m-%dT%H:%M:%SZ)" \
    --data-urlencode "interval.endTime=$(date -u -d "@$END" +%Y-%m-%dT%H:%M:%SZ)" \
    --data-urlencode "aggregation.alignmentPeriod=60s" --data-urlencode "aggregation.perSeriesAligner=$2" |
    jq -r '[.timeSeries[0].points[]? | (.value.doubleValue // (.value.int64Value | tonumber))] |
           if length == 0 then "nan" else (add / length * 100 | round / 100) end'
}

PODS=$(prom "avg_over_time(sum(kube_deployment_status_replicas_available{deployment=\"armonik-compute-plane-bench\"})[$WINDOW:15s])")
RATE=$(prom "avg_over_time(sum(armonik:tasks_ended:rate1m)[$WINDOW:15s])")

printf '| %s-%s | pods %s | tasks/s %s | per pod %s | busy %s | DB CPU %s | write IOPS %s | WAL MB/s %s | conns %s (active %s, waiting %s) | slot lag max MB %s | agent CPU m %s | node CPU max %s | SubmitTasks p95 ms %s |\n' \
  "$1" "$2" "$PODS" "$RATE" \
  "$(prom "avg_over_time((sum(armonik:tasks_ended:rate1m) / sum(kube_deployment_status_replicas_available{deployment=\"armonik-compute-plane-bench\"}))[$WINDOW:15s])")" \
  "$(prom "avg_over_time((sum(armonik_bench_tasks_dispatched) / sum(kube_deployment_status_replicas_available{deployment=\"armonik-compute-plane-bench\"}))[$WINDOW:15s])")" \
  "$(gcm database/cpu/utilization ALIGN_MEAN)" \
  "$(gcm database/disk/write_ops_count ALIGN_RATE)" \
  "$(prom "avg_over_time(rate(pg_armonik_wal_wal_bytes[1m])[$WINDOW:15s]) / 1e6")" \
  "$(prom "avg_over_time(sum(pg_armonik_connections_count)[$WINDOW:15s])")" \
  "$(prom "avg_over_time(sum(pg_armonik_connections_count{state=\"active\"})[$WINDOW:15s])")" \
  "$(prom "avg_over_time(sum(pg_armonik_connections_count{state=\"active\",wait_event_type!=\"none\"})[$WINDOW:15s])")" \
  "$(prom "max_over_time(max(pg_armonik_replication_slots_lag_bytes)[$WINDOW:15s]) / 1e6")" \
  "$(prom "avg_over_time(avg(armonik:container_cpu_millicores:rate1m{partition=\"bench\",container=\"agent\"})[$WINDOW:15s])")" \
  "$(prom "max_over_time(max(sum by (node) (rate(container_cpu_usage_seconds_total{container!=\"\"}[1m])) / on (node) kube_node_status_allocatable{resource=\"cpu\"} * on (node) group_left () (kube_node_labels{label_cloud_google_com_compute_class=\"workers\"} > 0))[$WINDOW:15s])")" \
  "$(prom "avg_over_time(histogram_quantile(0.95, sum by (le) (rate(GrpcTasksService_SubmitTasks_milliseconds_bucket[1m])))[$WINDOW:15s])")"

echo "Top statements (seconds of execution per second, mean over the window):"
kubectl get --raw "$PROM?time=$END&query=$(printf %s "topk(5, avg_over_time(sum by (queryid) (rate(pg_stat_statements_seconds_total[1m]))[$WINDOW:15s])) * on (queryid) group_left (query) max by (queryid, query) (pg_stat_statements_query_id)" | jq -sRr @uri)" |
  jq -r '.data.result[] | "  \(.value[1] | tonumber * 1000 | round / 1000) s/s  \(.metric.query // .metric.queryid | gsub("\\s+"; " ") | .[0:140])"'

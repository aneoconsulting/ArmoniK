#!/usr/bin/env sh
# One database step: 0 ms tasks on <pairs> bench pairs fed by <clients> clients, then the clients' statistics.
#
#   bench/db-step.sh <step name> <pairs> <clients> [tasks per client]
#
# Prints the UTC window of the step, for the time range of the dashboards.
set -eu
cd "$(dirname "$0")"

STEP=$1 PAIRS=$2 CLIENTS=$3 NTASKS=${4:-60000}

# By waves of WAVE pods (20): at startup every Core process holds the schema lock on one connection while DbUp opens
# another, so more processes starting at once than server connections behind a pooler deadlock until its timeout
WAVE=${WAVE:-20}
n=$(kubectl -n armonik get deploy armonik-compute-plane-bench -o jsonpath='{.spec.replicas}')
while [ "$n" -lt "$PAIRS" ]; do
  n=$((n + WAVE > PAIRS ? PAIRS : n + WAVE))
  kubectl -n armonik scale deploy/armonik-compute-plane-bench --replicas="$n"
  kubectl -n armonik rollout status deploy/armonik-compute-plane-bench --timeout=20m
done
kubectl -n armonik scale deploy/armonik-compute-plane-bench --replicas="$PAIRS"
kubectl -n armonik rollout status deploy/armonik-compute-plane-bench --timeout=20m

START=$(date -u +%H:%M:%S)
DOP=${DOP:-16} ./client.sh "$STEP" 0 "$NTASKS" "$CLIENTS"
kubectl -n armonik wait --for=condition=complete --timeout=90m -l "bench/run=$STEP" job || true
END=$(date -u +%H:%M:%S)
# The pairs are no longer needed: their Spot nodes go away a minute later (consolidation of the workers class)
kubectl -n armonik scale deploy/armonik-compute-plane-bench --replicas=0

echo "step $STEP: $PAIRS pairs, $CLIENTS clients x $NTASKS tasks, $START -> $END UTC"
for job in $(kubectl -n armonik get jobs -l "bench/run=$STEP" -o name); do
  kubectl -n armonik logs "$job" | grep -E 'executions stats|Throughput for session' |
    jq -c '.stats // {sessionThroughput, nTasks, timespan}'
done

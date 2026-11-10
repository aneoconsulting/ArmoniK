#!/usr/bin/env sh
# Runs bench clients as Jobs in the cluster, through the ingress Service (nginx spreads each gRPC request over the
# control plane pods; the control plane Service would pin each client connection to one pod). No load balancer, no
# client bandwidth limit. The image comes from the same Docker Hub cache as the control plane.
#
#   bench/client.sh <name> <task duration ms> <tasks per client> [clients]
#
# Environment: ENDPOINT (http://armonik-ingress.armonik.svc:5001), PARTITION (bench), DOP (16, batches submitted in
# parallel by a client), PAUSE (false: true pauses the session during the submission), PAYLOAD_KB (22), RESULT_KB (2),
# DOWNLOAD (false: the client does not fetch the results once the tasks are done, minutes of control plane work out of
# the measure), CORE_VERSION (0.41.4).
# Results: kubectl -n armonik logs job/<name>-<i> | grep -E 'executions stats|Throughput'
set -eu

NAME=$1 DURATION=$2 NTASKS=$3 CLIENTS=${4:-1}
REGISTRY=$(kubectl -n armonik get deploy armonik-control-plane \
  -o jsonpath='{.spec.template.spec.containers[0].image}' | sed 's#/dockerhubaneo/.*##')

i=1
while [ "$i" -le "$CLIENTS" ]; do
  kubectl -n armonik apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $NAME-$i
  labels: {app.kubernetes.io/part-of: bench-client, bench/run: $NAME}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 86400
  template:
    metadata:
      labels: {app.kubernetes.io/part-of: bench-client, bench/run: $NAME}
      # The cluster autoscaler would otherwise evict a client while it waits for its results, to empty a node
      annotations: {cluster-autoscaler.kubernetes.io/safe-to-evict: "false"}
    spec:
      restartPolicy: Never
      containers:
        - name: client
          image: $REGISTRY/dockerhubaneo/armonik_core_bench_test_client:${CORE_VERSION:-0.41.4}
          resources:
            requests: {cpu: "1", memory: 1Gi}
            limits: {cpu: "2", memory: 2Gi}
          env:
            - {name: GrpcClient__Endpoint, value: "${ENDPOINT:-http://armonik-ingress.armonik.svc:5001}"}
            - {name: BenchOptions__Partition, value: "${PARTITION:-bench}"}
            - {name: BenchOptions__NTasks, value: "$NTASKS"}
            - {name: BenchOptions__TaskDurationMs, value: "$DURATION"}
            - {name: BenchOptions__PayloadSize, value: "${PAYLOAD_KB:-22}"}
            - {name: BenchOptions__ResultSize, value: "${RESULT_KB:-2}"}
            - {name: BenchOptions__BatchSize, value: "100"}
            - {name: BenchOptions__DegreeOfParallelism, value: "${DOP:-16}"}
            - {name: BenchOptions__PauseSessionDuringSubmission, value: "${PAUSE:-false}"}
            - {name: BenchOptions__DownloadResults, value: "${DOWNLOAD:-false}"}
EOF
  i=$((i + 1))
done

# Region
region = "europe-west1"

# SUFFIX
suffix = "main"

kms = {
  key_ring   = "armonik-europe-west1"
  crypto_key = "armonik-europe-west1"
}

labels = {}

# List of ECR repositories to create
gar = {
  mongodb = [
    {
      image = "mongo"
      tag   = "6.0.7"
    }
  ],
  "armonik-control-plane" = [
    {
      image = "dockerhubaneo/armonik_control"
      tag   = "0.23.0"
    }
  ],
  "armonik-polling-agent" = [
    {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.23.0"
    }
  ],
  "armonik-worker" = [
    {
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.14.1"
    }
  ],
  "armonik-htcmock-worker" = [
    {
      image = "dockerhubaneo/armonik_core_htcmock_test_worker"
      tag   = "0.23.0"
    }
  ],
  "armonik-bench-worker" = [
    {
      image = "dockerhubaneo/armonik_core_bench_test_worker"
      tag   = "0.23.0"
    }
  ],
  "armonik-stream-worker" = [
    {
      image = "dockerhubaneo/armonik_core_stream_test_worker"
      tag   = "0.23.0"
    }
  ],
  "metrics-exporter" = [
    {
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.23.0"
    }
  ],
  "partition-metrics-exporter" = [
    {
      image = "dockerhubaneo/armonik_control_partition_metrics"
      tag   = "0.23.0"
    }
  ],
  "armonik-admin-app" = [
    {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.11.4"
    },
  ],
  mongosh = [
    {
      image = "rtsp/mongosh"
      tag   = "1.10.1"
    }
  ],
  seq = [
    {
      image = "datalust/seq"
      tag   = "2023.3"
    }
  ],
  seqcli = [
    {
      image = "datalust/seqcli"
      tag   = "2023.2"
    }
  ],
  grafana = [
    {
      image = "grafana/grafana"
      tag   = "10.0.2"
    }
  ],
  prometheus = [
    {
      image = "prom/prometheus"
      tag   = "v2.45.0"
    }
  ],
  "cluster-autoscaler" = [
    {
      image = "registry.k8s.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    }
  ],
  "metrics-server" = [
    {
      image = "registry.k8s.io/metrics-server/metrics-server"
      tag   = "v0.6.2"
    }
  ],
  "fluent-bit" = [
    {
      image = "fluent/fluent-bit"
      tag   = "2.1.7"
    }
  ],
  "node-exporter" = [
    {
      image = "prom/node-exporter"
      tag   = "v1.6.0"
    }
  ],
  nginx = [
    {
      image = "nginxinc/nginx-unprivileged"
      tag   = "1.25.1-alpine-slim"
    }
  ],
  keda = [
    {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.9.3"
    }
  ],
  "keda-metrics-apiserver" = [
    {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.9.3"
    }
  ]
}

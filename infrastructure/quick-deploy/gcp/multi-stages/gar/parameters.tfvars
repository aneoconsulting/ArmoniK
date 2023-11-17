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
      tag   = "0.19.3"
    },
    {
      image = "submitterpubsub"
      tag   = "0.19.3-pubsub"
    }
  ],
  "armonik-polling-agent" = [
    {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.19.3"
    },
    {
      image = "pollingagentpubsub"
      tag   = "0.19.3-pubsub"
    }
  ],
  "armonik-worker" = [
    {
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.12.5"
    }
  ],
  "armonik-htcmock-worker" = [
    {
      image = "dockerhubaneo/armonik_core_htcmock_test_worker"
      tag   = "0.19.3"
    }
  ],
  "armonik-bench-worker" = [
    {
      image = "dockerhubaneo/armonik_core_bench_test_worker"
      tag   = "0.19.3"
    }
  ],
  "armonik-stream-worker" = [
    {
      image = "dockerhubaneo/armonik_core_stream_test_worker"
      tag   = "0.19.3"
    }
  ],
  "metrics-exporter" = [
    {
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.19.3"
    }
  ],
  "partition-metrics-exporter" = [
    {
      image = "dockerhubaneo/armonik_control_partition_metrics"
      tag   = "0.19.3"
    }
  ],
  "armonik-admin-app" = [
    {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.10.3"
    },
    {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.9.5"
    },
    {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.8.1"
    }
  ],
  "armonik-admin-api" = [
    {
      image = "dockerhubaneo/armonik_admin_api"
      tag   = "0.8.1"
    }
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
  "aws-node-termination-handler" = [
    {
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.19.0"
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
  ],
  "aws-efs-csi-driver" = [
    {
      image = "amazon/aws-efs-csi-driver"
      tag   = "v1.5.1"
    }
  ],
  livenessprobe = [
    {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
      tag   = "v2.9.0-eks-1-22-19"
    }
  ],
  "node-driver-registrar" = [
    {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
      tag   = "v2.7.0-eks-1-22-19"
    }
  ],
  "external-provisioner" = [
    {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
      tag   = "v3.4.0-eks-1-22-19"
    }
  ]
}


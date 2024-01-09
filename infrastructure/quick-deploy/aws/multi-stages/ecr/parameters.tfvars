# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# Tags
tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}

# List of ECR repositories to create
ecr = {
  kms_key_id = ""
  repositories = {
    mongodb = {
      image = "mongo"
      tag   = "6.0.7"
    },
    "armonik-control-plane" = {
      image = "dockerhubaneo/armonik_control"
      tag   = "0.20.2"
    },
    "armonik-polling-agent" = {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.20.2"
    },
    "armonik-worker" = {
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.12.5"
    },
    "armonik-htcmock-worker" = {
      image = "dockerhubaneo/armonik_core_htcmock_test_worker"
      tag   = "0.20.2"
    },
    "armonik-bench-worker" = {
      image = "dockerhubaneo/armonik_core_bench_test_worker"
      tag   = "0.20.2"
    },
    "armonik-stream-worker" = {
      image = "dockerhubaneo/armonik_core_stream_test_worker"
      tag   = "0.20.2"
    },
    "metrics-exporter" = {
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.20.2"
    },
    "partition-metrics-exporter" = {
      image = "dockerhubaneo/armonik_control_partition_metrics"
      tag   = "0.20.2"
    },
    "armonik-admin-gui" = {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.11.1"
    },
    mongosh = {
      image = "rtsp/mongosh"
      tag   = "1.10.1"
    },
    seq = {
      image = "datalust/seq"
      tag   = "2023.3"
    },
    seqcli = {
      image = "datalust/seqcli"
      tag   = "2023.2"
    },
    grafana = {
      image = "grafana/grafana"
      tag   = "10.0.2"
    },
    prometheus = {
      image = "prom/prometheus"
      tag   = "v2.45.0"
    },
    "cluster-autoscaler" = {
      image = "registry.k8s.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    },
    "aws-node-termination-handler" = {
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.19.0"
    },
    "metrics-server" = {
      image = "registry.k8s.io/metrics-server/metrics-server"
      tag   = "v0.6.2"
    },
    "fluent-bit" = {
      image = "fluent/fluent-bit"
      tag   = "2.1.7"
    },
    "node-exporter" = {
      image = "prom/node-exporter"
      tag   = "v1.6.0"
    },
    nginx = {
      image = "nginxinc/nginx-unprivileged"
      tag   = "1.25.1-alpine-slim"
    },
    keda = {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.9.3"
    },
    "keda-metrics-apiserver" = {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.9.3"
    },
    "aws-efs-csi-driver" = {
      image = "amazon/aws-efs-csi-driver"
      tag   = "v1.5.1"
    },
    livenessprobe = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
      tag   = "v2.9.0-eks-1-22-19"
    },
    "node-driver-registrar" = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
      tag   = "v2.7.0-eks-1-22-19"
    },
    "external-provisioner" = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
      tag   = "v3.4.0-eks-1-22-19"
    }
  }
}

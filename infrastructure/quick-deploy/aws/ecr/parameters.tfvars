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
  repositories = [
    {
      name  = "mongodb"
      image = "mongo"
      tag   = "6.0.1"
    },
    {
      name  = "armonik-control-plane"
      image = "dockerhubaneo/armonik_control"
      tag   = "0.12.2"
    },
    {
      name  = "armonik-polling-agent"
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.12.2"
    },
    {
      name  = "armonik-worker"
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.9.2"
    },
    {
      name  = "metrics-exporter"
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.12.2"
    },
    {
      name  = "partition-metrics-exporter"
      image = "dockerhubaneo/armonik_control_partition_metrics"
      tag   = "0.12.2"
    },
    {
      name  = "armonik-admin-app"
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.9.0"
    },
    {
      name  = "armonik-admin-app-old"
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.8.0"
    },
    {
      name  = "armonik-admin-api-old"
      image = "dockerhubaneo/armonik_admin_api"
      tag   = "0.8.0"
    },
    {
      name  = "mongosh"
      image = "rtsp/mongosh"
      tag   = "1.7.1"
    },
    {
      name  = "seq"
      image = "datalust/seq"
      tag   = "2023.1"
    },
    {
      name  = "seqcli"
      image = "datalust/seqcli"
      tag   = "2023.1"
    },
    {
      name  = "grafana"
      image = "grafana/grafana"
      tag   = "9.3.6"
    },
    {
      name  = "prometheus"
      image = "prom/prometheus"
      tag   = "v2.42.0"
    },
    {
      name  = "cluster-autoscaler"
      image = "registry.k8s.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    },
    {
      name  = "aws-node-termination-handler"
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.19.0"
    },
    {
      name  = "metrics-server"
      image = "registry.k8s.io/metrics-server/metrics-server"
      tag   = "v0.6.2"
    },
    {
      name  = "fluent-bit"
      image = "fluent/fluent-bit"
      tag   = "2.0.9"
    },
    {
      name  = "node-exporter"
      image = "prom/node-exporter"
      tag   = "v1.5.0"
    },
    {
      name  = "nginx"
      image = "nginxinc/nginx-unprivileged"
      tag   = "1.23.3"
    },
    {
      name  = "keda"
      image = "ghcr.io/kedacore/keda"
      tag   = "2.9.3"
    },
    {
      name  = "keda-metrics-apiserver"
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.9.3"
    },
    {
      name  = "aws-efs-csi-driver"
      image = "amazon/aws-efs-csi-driver"
      tag   = "v1.5.1"
    },
    {
      name  = "livenessprobe"
      image = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
      tag   = "v2.9.0-eks-1-22-19"
    },
    {
      name  = "node-driver-registrar"
      image = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
      tag   = "v2.7.0-eks-1-22-19"
    },
    {
      name  = "external-provisioner"
      image = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
      tag   = "v3.4.0-eks-1-22-19"
    }
  ]
}

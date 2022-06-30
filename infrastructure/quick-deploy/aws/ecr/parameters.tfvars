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
  kms_key_id   = ""
  repositories = [
    {
      name  = "mongodb"
      image = "mongo"
      tag   = "5.0.9"
    },
    {
      name  = "armonik-control-plane"
      image = "dockerhubaneo/armonik_control"
      tag   = "0.5.15"
    },
    {
      name  = "armonik-polling-agent"
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.5.15"
    },
    {
      name  = "armonik-worker"
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.6.1"
    },
    {
      name  = "metrics-exporter"
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.5.15"
    },
    {
      name  = "armonik-admin-api"
      image = "dockerhubaneo/armonik_admin_api"
      tag   = "0.1.0"
    },
    {
      name  = "armonik-admin-app"
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.1.0"
    },
    {
      name  = "seq"
      image = "datalust/seq"
      tag   = "2022.1"
    },
    {
      name  = "grafana"
      image = "grafana/grafana"
      tag   = "8.5.5"
    },
    {
      name  = "prometheus"
      image = "prom/prometheus"
      tag   = "v2.36.1"
    },
    {
      name  = "cluster-autoscaler"
      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    },
    {
      name  = "aws-node-termination-handler"
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.15.0"
    },
    {
      name  = "fluent-bit"
      image = "fluent/fluent-bit"
      tag   = "1.9.5"
    },
    {
      name  = "node-exporter"
      image = "prom/node-exporter"
      tag   = "v1.3.1"
    },
    {
      name  = "nginx"
      image = "nginxinc/nginx-unprivileged"
      tag   = "1.23.0"
    },
    {
      name  = "keda"
      image = "ghcr.io/kedacore/keda"
      tag   = "2.7.1"
    },
    {
      name  = "keda-metrics-apiserver"
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.7.1"
    }
  ]
}

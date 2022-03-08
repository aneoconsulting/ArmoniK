# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# Tags
tags = {
  name             = ""
  env              = ""
  entity           = ""
  bu               = ""
  owner            = ""
  application_code = ""
  project_code     = ""
  cost_center      = ""
  support_contact  = ""
  origin           = ""
  unit_of_measure  = ""
  epic             = ""
  functional_block = ""
  hostname         = ""
  interruptible    = ""
  tostop           = ""
  tostart          = ""
  branch           = ""
  gridserver       = ""
  it_division      = ""
  confidentiality  = ""
  csp              = ""
}

# List of ECR repositories to create
ecr = {
  kms_key_id   = ""
  repositories = [
    {
      name  = "mongodb"
      image = "mongo"
      tag   = "4.4.11"
    },
    {
      name  = "redis"
      image = "redis"
      tag   = "bullseye"
    },
    {
      name  = "activemq"
      image = "symptoma/activemq"
      tag   = "5.16.3"
    },
    {
      name  = "armonik-control-plane"
      image = "dockerhubaneo/armonik_control"
      tag   = "0.5.0"
    },
    {
      name  = "armonik-polling-agent"
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.5.0"
    },
    {
      name  = "armonik-worker"
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.4.0"
    },
    {
      name  = "seq"
      image = "datalust/seq"
      tag   = "2021.4"
    },
    {
      name  = "grafana"
      image = "grafana/grafana"
      tag   = "latest"
    },
    {
      name  = "prometheus"
      image = "prom/prometheus"
      tag   = "latest"
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
      tag   = "1.7.2"
    },
    {
      name  = "node-exporter"
      image = "prom/node-exporter"
      tag   = "latest"
    },
    {
      name  = "prometheus-adapter"
      image = "k8s.gcr.io/prometheus-adapter/prometheus-adapter"
      tag   = "v0.9.1"
    },
    {
      name  = "metrics-exporter"
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.5.0"
    }
  ]
}
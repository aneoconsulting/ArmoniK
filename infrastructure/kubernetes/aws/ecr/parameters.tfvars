# Profile
profile = "default"

# Region
region = "eu-west-3"

# TAG
tag = ""

# KMS to encrypt ECR repositories
kms_key_id = ""

# List of ECR repositories to create
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
    name  = "control-plane"
    image = "dockerhubaneo/armonik_control"
    tag   = "0.2.2-aws.17.17a7585"
  },
  {
    name  = "polling-agent"
    image = "dockerhubaneo/armonik_pollingagent"
    tag   = "0.2.2-aws.17.17a7585"
  },
  {
    name  = "worker"
    image = "dockerhubaneo/armonik_worker_dll"
    tag   = "0.1.1"
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
    tag   = "v1.21.0"
  },
  {
    name  = "aws-node-termination-handler"
    image = "amazon/aws-node-termination-handler"
    tag   = "v1.10.0"
  }
]

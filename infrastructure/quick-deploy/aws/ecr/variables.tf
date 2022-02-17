# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}

# SUFFIX
variable "suffix" {
  description = "To suffix the AWS resources"
  type        = string
  default     = ""
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
  type        = any
  default     = {}
}

# List of ECR repositories to create
variable "ecr" {
  description = "List of ECR repositories to create"
  type        = object({
    kms_key_id   = string
    repositories = list(any)
  })
  default     = {
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
        tag   = "0.4.0"
      },
      {
        name  = "armonik-polling-agent"
        image = "dockerhubaneo/armonik_pollingagent"
        tag   = "0.4.0"
      },
      {
        name  = "armonik-worker"
        image = "dockerhubaneo/armonik_worker_dll"
        tag   = "0.1.2-SNAPSHOT.4.cfda5d1"
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
      },
      {
        name  = "fluent-bit"
        image = "fluent/fluent-bit"
        tag   = "1.3.11"
      }
    ]
  }
}
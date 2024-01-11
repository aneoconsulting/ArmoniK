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
  default     = "main"
}

# Aws account id
variable "aws_account_id" {
  description = "AWS account ID where the infrastructure will be deployed"
  type        = string
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
  type        = any
  default     = {}
}

# EKS infos
variable "eks" {
  description = "EKS cluster infos"
  type        = any
  default     = {}
}

# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = any
}

# S3 as shared storage
variable "s3_fs" {
  description = "AWS S3 bucket as shared storage"
  type = object({
    name                                  = string
    policy                                = string
    attach_policy                         = bool
    attach_deny_insecure_transport_policy = bool
    attach_require_latest_tls_policy      = bool
    attach_public_policy                  = bool
    block_public_acls                     = bool
    block_public_policy                   = bool
    ignore_public_acls                    = bool
    restrict_public_buckets               = bool
    kms_key_id                            = string
    sse_algorithm                         = string
    ownership                             = string
    versioning                            = string
  })
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type = object({
    name                        = string
    engine                      = string
    engine_version              = string
    node_type                   = string
    apply_immediately           = bool
    multi_az_enabled            = bool
    automatic_failover_enabled  = bool
    num_cache_clusters          = number
    preferred_cache_cluster_azs = list(string)
    data_tiering_enabled        = bool
    log_retention_in_days       = number
    cloudwatch_log_groups = object({
      slow_log   = string
      engine_log = string
    })
    encryption_keys = object({
      kms_key_id     = string
      log_kms_key_id = string
    })
  })
  default = null
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type = object({
    name                    = string
    engine_type             = string
    engine_version          = string
    host_instance_type      = string
    apply_immediately       = bool
    deployment_mode         = string
    storage_type            = string
    kms_key_id              = string
    authentication_strategy = string
    publicly_accessible     = bool
  })
}

# MQ Credentials
variable "mq_credentials" {
  description = "Amazon MQ credentials"
  type = object({
    password = string
    username = string
  })
  default = {
    password = ""
    username = ""
  }
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    replicas_number    = number
    security_context = object({
      run_as_user = number
      fs_group    = number
    })
    persistent_volume = object({
      storage_provisioner = string
      volume_binding_mode = string
      parameters          = map(string)
      #Resources for PVC
      resources = object({
        limits = object({
          storage = string
        })
        requests = object({
          storage = string
        })
      })
    })
  })
}

# AWS EFS as Persistent volume
variable "efs" {
  description = "AWS EFS as Persistent volume"
  type = object({
    name                            = string
    kms_key_id                      = string
    performance_mode                = string # "generalPurpose" or "maxIO"
    throughput_mode                 = string #  "bursting" or "provisioned"
    provisioned_throughput_in_mibps = number
    transition_to_ia                = string
    # "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", or "AFTER_90_DAYS"
    access_point = list(string)
  })
}

# S3 as object storage
variable "s3_os" {
  description = "AWS S3 bucket as shared storage"
  type = object({
    name                                  = string
    policy                                = string
    attach_policy                         = bool
    attach_deny_insecure_transport_policy = bool
    attach_require_latest_tls_policy      = bool
    attach_public_policy                  = bool
    block_public_acls                     = bool
    block_public_policy                   = bool
    ignore_public_acls                    = bool
    restrict_public_buckets               = bool
    kms_key_id                            = string
    sse_algorithm                         = string
    ownership                             = string
    versioning                            = string
  })
  default = null
}
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

# TAG
variable "tag" {
  description = "Tag to prefix the AWS resources"
  type        = string
  default     = ""
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
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
  type        = object({
    id                     = string
    cidr_block             = string
    private_subnet_ids     = list(string)
    pod_cidr_block_private = list(string)
    pods_subnet_ids        = list(string)
  })
  default     = {
    id                     = ""
    cidr_block             = ""
    private_subnet_ids     = []
    pod_cidr_block_private = []
    pods_subnet_ids        = []
  }
}

# S3 as shared storage
variable "s3_fs" {
  description = "AWS S3 bucket as shared storage"
  type        = object({
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
  })
  default     = {
    name                                  = "armonik-s3fs"
    policy                                = ""
    attach_policy                         = false
    attach_deny_insecure_transport_policy = true
    attach_require_latest_tls_policy      = true
    attach_public_policy                  = false
    block_public_acls                     = true
    block_public_policy                   = true
    ignore_public_acls                    = true
    restrict_public_buckets               = true
    kms_key_id                            = ""
    sse_algorithm                         = ""
  }
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
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
    encryption_keys             = object({
      kms_key_id     = string
      log_kms_key_id = string
    })
  })
  default     = {
    name                        = "armonik-elasticache"
    engine                      = "redis"
    engine_version              = "6.x"
    node_type                   = "cache.r4.large"
    apply_immediately           = false
    multi_az_enabled            = false
    automatic_failover_enabled  = true
    num_cache_clusters          = 2
    preferred_cache_cluster_azs = []
    # The order of the availability zones in the list is considered. The first item in the list will be the primary node
    data_tiering_enabled        = false # This parameter must be set to true when using r6gd nodes.
    log_retention_in_days       = 30
    encryption_keys             = {
      kms_key_id     = ""
      log_kms_key_id = ""
    }
  }
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type        = object({
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
  default     = {
    name                    = "armonik-mq"
    engine_type             = "ActiveMQ"
    engine_version          = "5.16.3"
    host_instance_type      = "mq.m5.large"
    apply_immediately       = false
    deployment_mode         = "ACTIVE_STANDBY_MULTI_AZ"
    # "SINGLE_INSTANCE" | "ACTIVE_STANDBY_MULTI_AZ" | "CLUSTER_MULTI_AZ"
    storage_type            = "efs" #"ebs"
    kms_key_id              = ""
    authentication_strategy = "simple" #"ldap"
    publicly_accessible     = false
  }
}

# MQ Credentials
variable "mq_credentials" {
  description = "Amazon MQ credentials"
  type        = object({
    password = string
    username = string
  })
  default     = {
    password = ""
    username = ""
  }
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    image         = string
    tag           = string
    node_selector = any
  })
}

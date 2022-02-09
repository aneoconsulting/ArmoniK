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

# S3 as shared storage
variable "s3_bucket_fs" {
  description = "AWS S3 bucket as shared storage"
  type        = object({
    name       = string
    kms_key_id = string
  })
  default     = {
    name       = "armonik-s3fs"
    kms_key_id = ""
  }
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
    name                  = string
    engine                = string
    engine_version        = string
    node_type             = string
    encryption_keys       = object({
      kms_key_id     = string
      log_kms_key_id = string
    })
    log_retention_in_days = number
    multi_az_enabled      = bool
    vpc                   = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
    cluster_mode          = object({
      replicas_per_node_group = number
      num_node_groups         = number
    })
  })
  default     = {
    name                  = "armonik-elasticache"
    engine                = "redis"
    engine_version        = "6.x"
    node_type             = "cache.r4.large"
    encryption_keys       = {
      kms_key_id     = ""
      log_kms_key_id = ""
    }
    log_retention_in_days = 30
    vpc                   = {
      id          = ""
      cidr_blocks = []
      subnet_ids  = []
    }
    multi_az_enabled      = false
    cluster_mode          = {
      replicas_per_node_group = 0
      num_node_groups         = 1 #Valid values are 0 to 5
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
    deployment_mode         = string
    storage_type            = string
    kms_key_id              = string
    authentication_strategy = string
    publicly_accessible     = bool
    vpc                     = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
  })
  default     = {
    name                    = "armonik-mq"
    engine_type             = "ActiveMQ"
    engine_version          = "5.16.3"
    host_instance_type      = "mq.m5.large"
    deployment_mode         = "ACTIVE_STANDBY_MULTI_AZ" #"SINGLE_INSTANCE"
    storage_type            = "efs" #"ebs"
    kms_key_id              = ""
    authentication_strategy = "simple" #"ldap"
    publicly_accessible     = false
    vpc                     = {
      id          = ""
      cidr_blocks = []
      subnet_ids  = []
    }
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
  sensitive   = true
}

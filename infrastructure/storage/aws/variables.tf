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

# AWS VPC of EKS
variable "armonik_vpc_id" {
  description = "AWS VPC ID of ArmoniK EKS"
  type        = string
  default     = ""
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
    engine           = string
    engine_version   = string
    node_type        = string
    kms_key_id       = string
    multi_az_enabled = bool
    vpc              = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
    cluster_mode     = object({
      replicas_per_node_group = number
      num_node_groups         = number
    })
    tags             = any
  })
  default     = {
    engine           = "redis"
    engine_version   = "6.x"
    node_type        = "cache.r4.large"
    kms_key_id       = ""
    vpc              = {
      id          = ""
      cidr_blocks = []
      subnet_ids  = []
    }
    multi_az_enabled = false
    cluster_mode     = {
      replicas_per_node_group = 0
      num_node_groups         = 1 #Valid values are 0 to 5
    }
    tags             = {}
  }
}
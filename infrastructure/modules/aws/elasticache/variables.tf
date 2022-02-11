# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# Elatsicache name
variable "name" {
  description = "AWS Elasticache service name"
  type        = string
  default     = "armonik-elasticache"
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = object({
    id          = string
    cidr_blocks = list(string)
    subnet_ids  = list(string)
  })
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
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
}
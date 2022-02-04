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
  })
}
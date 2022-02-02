# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
    tag              = string
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
}
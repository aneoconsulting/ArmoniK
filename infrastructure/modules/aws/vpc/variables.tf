# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# VPC name
variable "name" {
  description = "AWS VPC service name"
  type        = string
  default     = "armonik-vpc"
}

# VPC
variable "vpc" {
  description = "Parameters of AWS VPC"
  type        = object({
    cluster_name                                    = string
    main_cidr_block                                 = string
    pod_cidr_block_private                          = list(string)
    private_subnets                                 = list(string)
    public_subnets                                  = list(string)
    enable_private_subnet                           = bool
    enable_nat_gateway                              = bool
    single_nat_gateway                              = bool
    flow_log_cloudwatch_log_group_kms_key_id        = string
    flow_log_cloudwatch_log_group_retention_in_days = number
    peering                                         = object({
      enabled      = bool
      peer_vpc_ids = list(string)
    })
  })
}
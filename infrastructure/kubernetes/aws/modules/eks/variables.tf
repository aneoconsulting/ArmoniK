# EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    region                               = string
    cluster_name                         = string
    cluster_version                      = string
    vpc_private_subnet_ids               = list(string)
    vpc_id                               = string
    pods_subnet_ids                      = list(string)
    enable_private_subnet                = bool
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    encryption_keys                      = object({
      cluster_log_kms_key_id    = string
      cluster_encryption_config = string
      ebs_kms_key_id            = string
    })
    cluster_log_retention_in_days        = number
    shared_storage                       = string
    tags                                 = map(string)
  })
}
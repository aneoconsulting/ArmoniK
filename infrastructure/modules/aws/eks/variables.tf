# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# EKS name
variable "name" {
  description = "AWS EKS service name"
  type        = string
  default     = "armonik-eks"
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = object({
    id                 = string
    private_subnet_ids = list(string)
    pods_subnet_ids    = list(string)
  })
}

# Shared storage info
variable "s3_fs" {
  description = "S3 bucket used as shared storage"
  type        = object({
    name       = string
    kms_key_id = string
    host_path  = string
  })
}

# EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    cluster_version                      = string
    cluster_endpoint_private_access      = bool
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    cluster_log_retention_in_days        = number
    docker_images                        = object({
      cluster_autoscaler = object({
        image = string
        tag   = string
      })
      instance_refresh   = object({
        image = string
        tag   = string
      })
    })
    encryption_keys                      = object({
      cluster_log_kms_key_id    = string
      cluster_encryption_config = string
      ebs_kms_key_id            = string
    })
  })
}

# Worker node groups
variable "eks_worker_groups" {
  description = "List of EKS worker node groups"
  type        = any
}
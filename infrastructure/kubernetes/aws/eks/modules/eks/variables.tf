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
    tags                                 = map(string)
  })
}

# Worker node groups
variable "eks_worker_groups" {
  description = "List of EKS worker node groups"
  type        = any
}

# Encryption at rest
variable "encryption_keys" {
  description = "Encryption keys ARN for EKS components"
  type        = object({
    cluster_log_kms_key_id    = string
    cluster_encryption_config = string
    ebs_kms_key_id            = string
  })
}

# Shared storage for EKS pods
variable "s3_bucket_shared_storage" {
  description = "S3 bucket as shared storage for EKS pods"
  type        = object({
    id         = string
    host_path  = string
    kms_key_id = string
  })
}
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

# SUFFIX
variable "suffix" {
  description = "To suffix the AWS resources"
  type        = string
  default     = ""
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
  type        = any
  default     = {}
}

# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
  type        = any
  default     = {}
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = any
  default     = {}
}

# AWS EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type = object({
    name                                  = string
    cluster_version                       = string
    cluster_endpoint_private_access       = bool # vpc.enable_private_subnet
    cluster_endpoint_private_access_cidrs = list(string)
    cluster_endpoint_private_access_sg    = list(string)
    cluster_endpoint_public_access        = bool
    cluster_endpoint_public_access_cidrs  = list(string)
    cluster_log_retention_in_days         = number
    docker_images = object({
      cluster_autoscaler = object({
        image = string
        tag   = string
      })
      instance_refresh = object({
        image = string
        tag   = string
      })
    })
    cluster_autoscaler = object({
      expander                              = string
      scale_down_enabled                    = bool
      min_replica_count                     = number
      scale_down_utilization_threshold      = number
      scale_down_non_empty_candidates_count = number
      max_node_provision_time               = string
      scan_interval                         = string
      scale_down_delay_after_add            = string
      scale_down_delay_after_delete         = string
      scale_down_delay_after_failure        = string
      scale_down_unneeded_time              = string
      skip_nodes_with_system_pods           = bool
    })
    encryption_keys = object({
      cluster_log_kms_key_id    = string
      cluster_encryption_config = string
      ebs_kms_key_id            = string
    })
    map_roles = list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    }))
    map_users = list(object({
      userarn  = string
      username = string
      groups   = list(string)
    }))
  })
}

# Operational node groups for EKS
variable "eks_operational_worker_groups" {
  description = "List of EKS operational node groups"
  type        = any
}

# EKS worker groups
variable "eks_worker_groups" {
  description = "List of EKS worker node groups"
  type        = any
}
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
  default     = null
}

# VPC
variable "vpc" {
  description = "Parameters of AWS VPC"
  type        = object({
    # list of CIDR block associated with the private subnet
    cidr_block_private                              = list(string)
    # list of CIDR block associated with the public subnet
    cidr_block_public                               = list(string)
    # Main CIDR block associated to the VPC
    main_cidr_block                                 = string
    # cidr block associated with pod
    pod_cidr_block_private                          = list(string)
    enable_private_subnet                           = bool
    flow_log_cloudwatch_log_group_kms_key_id        = string
    flow_log_cloudwatch_log_group_retention_in_days = number
  })
  default     = {
    # list of CIDR block associated with the private subnet
    cidr_block_private                              = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
    # list of CIDR block associated with the public subnet
    cidr_block_public                               = ["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"]
    # Main CIDR block associated to the VPC
    main_cidr_block                                 = "10.0.0.0/16"
    # cidr block associated with pod
    pod_cidr_block_private                          = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
    enable_private_subnet                           = true
    flow_log_cloudwatch_log_group_kms_key_id        = ""
    flow_log_cloudwatch_log_group_retention_in_days = 30
  }
}

# S3 bucket as Filesystem
variable "s3fs_bucket" {
  description = "AWS S3 bucket to be used as filesystem shared between pods"
  type        = object({
    name       = string
    kms_key_id = string
    tags       = object({})
  })
  default     = {
    name       = "s3fs"
    kms_key_id = ""
    tags       = {}
  }
}

# EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    cluster_version                      = string
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    encryption_keys                      = object({
      cluster_log_kms_key_id    = string
      cluster_encryption_config = string
      ebs_kms_key_id            = string
    })
    cluster_log_retention_in_days        = number
  })
  default     = {
    cluster_version                      = "1.21"
    cluster_endpoint_public_access       = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
    encryption_keys                      = {
      cluster_log_kms_key_id    = ""
      cluster_encryption_config = ""
      ebs_kms_key_id            = ""
    }
    cluster_log_retention_in_days        = 30
  }
}

# EKS worker groups
variable "eks_worker_groups" {
  description = "EKS worker groups"
  type        = list(object({}))
  default     = [{}]
}
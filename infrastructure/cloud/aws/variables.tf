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
  default     = "main"
}

# ARN of encrypt/decrypt keys
variable "encryption_keys_arn" {
  description = "List of encryption keys ARN"
  type        = object({
    vpc_flow_log_cloudwatch_log_group = string
    eks                               = object({
      secrets              = string
      ebs                  = string
      cloudwatch_log_group = string
    })
  })
  default     = {
    vpc_flow_log_cloudwatch_log_group = ""
    eks                               = {
      secrets              = ""
      ebs                  = ""
      cloudwatch_log_group = ""
    }
  }
}

# KMS
variable "kms_parameters" {
  description = "AWS Key Management Service parameters"
  type        = object({
    name                     = string
    multi_region             = bool
    deletion_window_in_days  = number
    customer_master_key_spec = string
    key_usage                = string
    enable_key_rotation      = bool
    is_enabled               = bool
  })
  default     = {
    name                     = "armonik-kms"
    multi_region             = false
    deletion_window_in_days  = 7
    customer_master_key_spec = "SYMMETRIC_DEFAULT"
    key_usage                = "ENCRYPT_DECRYPT"
    enable_key_rotation      = true
    is_enabled               = true
  }
}

# VPC
variable "vpc_parameters" {
  description = "Parameters of AWS VPC"
  type        = object({
    name                                            = string
    cidr                                            = string
    private_subnets_cidr                            = list(string)
    public_subnets_cidr                             = list(string)
    enable_private_subnet                           = bool
    flow_log_cloudwatch_log_group_retention_in_days = number
  })
  default     = {
    name                                            = "armonik-vpc"
    cidr                                            = "10.0.0.0/16"
    private_subnets_cidr                            = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
    public_subnets_cidr                             = ["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"]
    enable_private_subnet                           = true
    flow_log_cloudwatch_log_group_retention_in_days = 30
  }
}

# EKS
variable "eks_parameters" {
  description = "Parameters of AWS EKS"
  type        = object({
    name                                   = string
    version                                = string
    cloudwatch_log_group_retention_in_days = number
    cluster_endpoint_public_access         = bool
    cluster_endpoint_public_access_cidrs   = list(string)
  })
  default     = {
    name                                   = "armonik-eks"
    version                                = "1.21"
    cloudwatch_log_group_retention_in_days = 30
    cluster_endpoint_public_access         = true
    cluster_endpoint_public_access_cidrs   = ["0.0.0.0/0"]
  }
}
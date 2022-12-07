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

# EKS cluster name
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

# VPC
variable "vpc" {
  description = "Parameters of AWS VPC"
  type        = object({
    name                                            = string
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
    peering                                         = object({
      enabled      = bool
      peer_vpc_ids = list(string)
    })
  })
}

# Enable public VPC
variable "enable_public_vpc" {
  description = "Enable public VPC"
  type        = string
  default     = null
}
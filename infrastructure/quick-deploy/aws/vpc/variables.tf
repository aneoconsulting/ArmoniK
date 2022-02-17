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
  })
  default     = {
    name                                            = "armonik-vpc"
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
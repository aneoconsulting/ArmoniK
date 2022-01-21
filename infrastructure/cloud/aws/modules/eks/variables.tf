# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
}

# TAG
variable "tag" {
  description = "Tag to prefix the AWS resources"
  type        = string
}

# Account ID
variable "account" {
  description = "Account ID that will have permissions."
  type        = any
}

# Cluster name
variable "cluster_name" {
  description = "Name of AWS EKS."
  type        = string
}

# eks
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    version                                = string
    vpc                                    = any
    encryption_keys_arn                    = object({
      secrets              = string
      ebs                  = string
      cloudwatch_log_group = string
    })
    cloudwatch_log_group_retention_in_days = number
    enable_private_subnet                  = bool
    cluster_endpoint_public_access         = bool
    cluster_endpoint_public_access_cidrs   = list(string)
  })
}
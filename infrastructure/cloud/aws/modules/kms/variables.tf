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

# KMS
variable "kms" {
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
}
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
# KMS parameters
variable "kms" {
  description = "AWS Key Management Service parameters"
  type        = object({
    name                     = string
    region                   = string
    account_id               = string
    multi_region             = bool
    deletion_window_in_days  = number
    customer_master_key_spec = string
    key_usage                = string
    enable_key_rotation      = bool
    is_enabled               = bool
    tags                     = map(string)
  })
}
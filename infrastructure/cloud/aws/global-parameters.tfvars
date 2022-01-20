# Region
region = "eu-west-3"

# TAG
tag = "main"

# KMS
kms = {
  name                     = "armonik-kms"
  multi_region             = false
  deletion_window_in_days  = 7
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  enable_key_rotation      = true
  is_enabled               = true
}
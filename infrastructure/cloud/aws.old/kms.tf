# KMS
module "kms" {
  source  = "./modules/kms"
  region  = var.region
  tag     = local.tag
  account = module.account.current_account
  kms     = {
    name                     = var.kms_parameters.name
    multi_region             = var.kms_parameters.multi_region
    deletion_window_in_days  = var.kms_parameters.deletion_window_in_days
    customer_master_key_spec = var.kms_parameters.customer_master_key_spec
    key_usage                = var.kms_parameters.key_usage
    enable_key_rotation      = var.kms_parameters.enable_key_rotation
    is_enabled               = var.kms_parameters.is_enabled
  }
}
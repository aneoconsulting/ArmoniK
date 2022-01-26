# KMS
module "kms" {
  source = "./modules/kms"
  kms    = {
    name                     = "${var.kms.name}-${local.tag}"
    region                   = var.region
    account_id               = data.aws_caller_identity.current.id
    multi_region             = var.kms.multi_region
    deletion_window_in_days  = var.kms.deletion_window_in_days
    customer_master_key_spec = var.kms.customer_master_key_spec
    key_usage                = var.kms.key_usage
    enable_key_rotation      = var.kms.enable_key_rotation
    is_enabled               = var.kms.is_enabled
    tags                     = local.tags
  }
}
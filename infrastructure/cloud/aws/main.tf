# Account
module "account" {
  source = "./modules/account"
  region = var.region
}

# KMS
module "kms" {
  source     = "./modules/kms"
  region     = var.region
  tag        = var.tag
  account_id = module.account.current_account.id
  kms        = var.kms
}
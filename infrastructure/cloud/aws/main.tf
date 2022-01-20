# Account
module "account" {
  source = "./modules/account"
  region = var.region
}

# KMS
module "kms" {
  source  = "./modules/kms"
  region  = var.region
  tag     = var.tag
  account = module.account.current_account
  kms     = var.kms
}
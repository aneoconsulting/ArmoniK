# Account
module "account" {
  source = "./modules/account"
  region = var.region
}

# KMS
module "kms" {
  source  = "./modules/kms"
  region  = var.region
  tag     = local.tag
  account = module.account.current_account
  kms     = var.kms
}

# VPC
module "vpc" {
  source       = "./modules/vpc"
  region       = var.region
  account      = module.account.current_account
  tag          = local.tag
  cluster_name = local.cluster_name
  vpc          = var.vpc
}
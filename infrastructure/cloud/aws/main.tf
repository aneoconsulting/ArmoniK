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

# VPC
module "vpc" {
  source         = "./modules/vpc"
  region         = var.region
  tag            = local.tag
  account        = module.account.current_account
  cluster_name   = local.cluster_name
  vpc_parameters = {
    name                                            = var.vpc_parameters.name
    cidr                                            = var.vpc_parameters.cidr
    private_subnets_cidr                            = var.vpc_parameters.private_subnets_cidr
    public_subnets_cidr                             = var.vpc_parameters.public_subnets_cidr
    enable_private_subnet                           = var.vpc_parameters.enable_private_subnet
    flow_log_cloudwatch_log_group_kms_key_id        = (var.encryption_keys_arn.vpc_flow_log_cloudwatch_log_group != "" ? var.encryption_keys_arn.vpc_flow_log_cloudwatch_log_group : module.kms.selected.arn)
    flow_log_cloudwatch_log_group_retention_in_days = var.vpc_parameters.flow_log_cloudwatch_log_group_retention_in_days
  }
}

# EKS
module "eks" {
  source       = "./modules/eks"
  region       = var.region
  tag          = local.tag
  account      = module.account.current_account
  cluster_name = local.cluster_name
  eks          = {
    version                                = var.eks_parameters.version
    vpc                                    = module.vpc.selected
    encryption_keys_arn                    = {
      secrets              = (var.encryption_keys_arn.eks.secrets != "" ? var.encryption_keys_arn.eks.secrets : module.kms.selected.arn)
      ebs                  = (var.encryption_keys_arn.eks.ebs != "" ? var.encryption_keys_arn.eks.ebs : module.kms.selected.arn)
      cloudwatch_log_group = (var.encryption_keys_arn.eks.cloudwatch_log_group != "" ? var.encryption_keys_arn.eks.cloudwatch_log_group : module.kms.selected.arn)
    }
    cloudwatch_log_group_retention_in_days = var.eks_parameters.cloudwatch_log_group_retention_in_days
    enable_private_subnet                  = var.vpc_parameters.enable_private_subnet
    cluster_endpoint_public_access         = var.eks_parameters.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs   = var.eks_parameters.cluster_endpoint_public_access_cidrs
  }
}
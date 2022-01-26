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
    flow_log_cloudwatch_log_group_kms_key_id        = (var.encryption_keys_arn.vpc_flow_log_cloudwatch_log_group != "" ? var.encryption_keys_arn.vpc_flow_log_cloudwatch_log_group : module.kms.armonik.arn)
    flow_log_cloudwatch_log_group_retention_in_days = var.vpc_parameters.flow_log_cloudwatch_log_group_retention_in_days
  }
}
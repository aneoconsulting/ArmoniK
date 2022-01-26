# EKS
module "eks" {
  source       = "./modules/eks"
  region       = var.region
  tag          = local.tag
  account      = module.account.current_account
  cluster_name = local.cluster_name
  eks          = {
    version                                = var.eks_parameters.version
    vpc                                    = module.vpc.armonik
    encryption_keys_arn                    = {
      secrets              = (var.encryption_keys_arn.eks.secrets != "" ? var.encryption_keys_arn.eks.secrets : module.kms.armonik.arn)
      cloudwatch_log_group = (var.encryption_keys_arn.eks.cloudwatch_log_group != "" ? var.encryption_keys_arn.eks.cloudwatch_log_group : module.kms.armonik.arn)
    }
    cloudwatch_log_group_retention_in_days = var.eks_parameters.cloudwatch_log_group_retention_in_days
    enable_private_subnet                  = var.vpc_parameters.enable_private_subnet
    cluster_endpoint_public_access         = var.eks_parameters.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs   = var.eks_parameters.cluster_endpoint_public_access_cidrs
  }
}
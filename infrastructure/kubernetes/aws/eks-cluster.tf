module "eks" {
  source = "./modules/eks"
  eks    = {
    region                               = var.region
    cluster_name                         = local.cluster_name
    cluster_version                      = var.eks.cluster_version
    vpc_private_subnet_ids               = module.vpc.private_subnet_ids
    vpc_id                               = module.vpc.selected.vpc_id
    pods_subnet_ids                      = module.vpc.pods_subnet_ids
    enable_private_subnet                = var.vpc.enable_private_subnet
    cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
    encryption_keys                      = {
      cluster_log_kms_key_id    = (var.eks.encryption_keys.cluster_log_kms_key_id != "" ? var.eks.encryption_keys.cluster_log_kms_key_id : module.kms.selected.arn)
      cluster_encryption_config = (var.eks.encryption_keys.cluster_encryption_config != "" ? var.eks.encryption_keys.cluster_encryption_config : module.kms.selected.arn)
      ebs_kms_key_id            = (var.eks.encryption_keys.ebs_kms_key_id != "" ? var.eks.encryption_keys.ebs_kms_key_id : module.kms.selected.arn)
    }
    cluster_log_retention_in_days        = var.eks.cluster_log_retention_in_days
    tags                                 = local.tags
  }
}
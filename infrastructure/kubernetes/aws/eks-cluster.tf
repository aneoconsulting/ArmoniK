module "eks" {
  source = "./modules/eks"

  # EKS
  eks = {
    region                               = var.region
    cluster_name                         = local.cluster_name
    cluster_version                      = var.eks.cluster_version
    vpc_private_subnet_ids               = module.vpc.private_subnet_ids
    vpc_id                               = module.vpc.selected.vpc_id
    pods_subnet_ids                      = module.vpc.pods_subnet_ids
    enable_private_subnet                = var.vpc.enable_private_subnet
    cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
    cluster_log_retention_in_days        = var.eks.cluster_log_retention_in_days
    tags                                 = local.tags
  }

  # EKS worker groups
  eks_worker_groups = var.eks_worker_groups

  # Encryption keys for EKS components
  encryption_keys = {
    cluster_log_kms_key_id    = (var.encryption_keys.cluster_log_kms_key_id != "" ? var.encryption_keys.cluster_log_kms_key_id : module.kms.selected.arn)
    cluster_encryption_config = (var.encryption_keys.cluster_encryption_config != "" ? var.encryption_keys.cluster_encryption_config : module.kms.selected.arn)
    ebs_kms_key_id            = (var.encryption_keys.ebs_kms_key_id != "" ? var.encryption_keys.ebs_kms_key_id : module.kms.selected.arn)
  }

  # S3 bucket as shared storage for pods
  s3_bucket_shared_storage = {
    id         = module.s3fs_bucket.selected.s3_bucket_id
    host_path  = var.s3fs_bucket.shared_host_path
    kms_key_id = (module.s3fs_bucket.kms_key_id != "" ? module.s3fs_bucket.kms_key_id : module.kms.selected.arn)
  }
}
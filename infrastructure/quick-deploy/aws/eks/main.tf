# AWS KMS
module "kms" {
  count  = (var.eks.encryption_keys.cluster_log_kms_key_id != "" && var.eks.encryption_keys.cluster_encryption_config != "" && var.eks.encryption_keys.ebs_kms_key_id != "" ? 0 : 1)
  source = "../../../modules/aws/kms"
  name   = "armonik-kms-eks-${local.suffix}-${local.random_string}"
  tags   = local.tags
}

# AWS EKS
module "eks" {
  source                        = "../../../modules/aws/eks"
  tags                          = local.tags
  name                          = local.cluster_name
  vpc                           = {
    id                 = var.vpc.id
    private_subnet_ids = var.vpc.private_subnet_ids
    pods_subnet_ids    = var.vpc.pods_subnet_ids
  }
  s3_fs                         = {
    name       = var.s3_fs.name
    kms_key_id = var.s3_fs.kms_key_id
    host_path  = var.s3_fs.host_path
  }
  eks                           = {
    region                               = var.region
    cluster_version                      = var.eks.cluster_version
    cluster_endpoint_private_access      = var.eks.cluster_endpoint_private_access
    cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
    cluster_log_retention_in_days        = var.eks.cluster_log_retention_in_days
    docker_images                        = {
      cluster_autoscaler = {
        image = var.eks.docker_images.cluster_autoscaler.image
        tag   = var.eks.docker_images.cluster_autoscaler.tag
      }
      instance_refresh   = {
        image = var.eks.docker_images.instance_refresh.image
        tag   = var.eks.docker_images.instance_refresh.tag
      }
    }
    encryption_keys                      = {
      cluster_log_kms_key_id    = (var.eks.encryption_keys.cluster_log_kms_key_id != "" ? var.eks.encryption_keys.cluster_log_kms_key_id : module.kms.0.selected.arn)
      cluster_encryption_config = (var.eks.encryption_keys.cluster_encryption_config != "" ? var.eks.encryption_keys.cluster_encryption_config : module.kms.0.selected.arn)
      ebs_kms_key_id            = (var.eks.encryption_keys.ebs_kms_key_id != "" ? var.eks.encryption_keys.ebs_kms_key_id : module.kms.0.selected.arn)
    }
  }
  eks_operational_worker_groups = var.eks_operational_worker_groups
  eks_worker_groups             = var.eks_worker_groups
  depends_on                    = [null_resource.empty_kubeconfig]
}
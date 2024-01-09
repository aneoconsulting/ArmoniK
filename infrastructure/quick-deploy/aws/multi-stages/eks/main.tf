# AWS KMS
module "kms" {
  count  = (var.eks.encryption_keys.cluster_log_kms_key_id != "" && var.eks.encryption_keys.cluster_encryption_config != "" && var.eks.encryption_keys.ebs_kms_key_id != "" ? 0 : 1)
  source = "../generated/infra-modules/security/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS EKS
module "eks" {
  source          = "../generated/infra-modules/kubernetes/aws/eks"
  profile         = var.profile
  tags            = local.tags
  name            = local.cluster_name
  node_selector   = var.node_selector
  kubeconfig_file = abspath(var.kubeconfig_file)
  vpc = {
    id                 = local.vpc.id
    private_subnet_ids = local.vpc.private_subnet_ids
    pods_subnet_ids    = local.vpc.pods_subnet_ids
  }
  eks = {
    region                                = var.region
    cluster_version                       = var.eks.cluster_version
    cluster_endpoint_private_access       = var.eks.cluster_endpoint_private_access
    cluster_endpoint_private_access_cidrs = var.eks.cluster_endpoint_private_access_cidrs
    cluster_endpoint_private_access_sg    = var.eks.cluster_endpoint_private_access_sg
    cluster_endpoint_public_access        = local.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs  = var.eks.cluster_endpoint_public_access_cidrs
    cluster_log_retention_in_days         = var.eks.cluster_log_retention_in_days
    docker_images = {
      cluster_autoscaler = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.cluster_autoscaler.image}"
        tag   = var.eks.docker_images.cluster_autoscaler.tag
      }
      instance_refresh = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.instance_refresh.image}"
        tag   = var.eks.docker_images.instance_refresh.tag
      }
      efs_csi = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.efs_csi.image}"
        tag   = var.eks.docker_images.efs_csi.tag
      }
      livenessprobe = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.livenessprobe.image}"
        tag   = var.eks.docker_images.livenessprobe.tag
      }
      node_driver_registrar = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.node_driver_registrar.image}"
        tag   = var.eks.docker_images.node_driver_registrar.tag
      }
      external_provisioner = {
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.external_provisioner.image}"
        tag   = var.eks.docker_images.external_provisioner.tag
      }
    }
    instance_refresh   = var.eks.instance_refresh
    cluster_autoscaler = var.eks.cluster_autoscaler
    efs_csi            = var.eks.efs_csi
    encryption_keys = {
      cluster_log_kms_key_id    = (var.eks.encryption_keys.cluster_log_kms_key_id != "" ? var.eks.encryption_keys.cluster_log_kms_key_id : module.kms.0.arn)
      cluster_encryption_config = (var.eks.encryption_keys.cluster_encryption_config != "" ? var.eks.encryption_keys.cluster_encryption_config : module.kms.0.arn)
      ebs_kms_key_id            = (var.eks.encryption_keys.ebs_kms_key_id != "" ? var.eks.encryption_keys.ebs_kms_key_id : module.kms.0.arn)
    }
    map_roles = var.eks.map_roles
    map_users = var.eks.map_users
  }
  eks_managed_node_groups  = var.eks_managed_node_groups
  self_managed_node_groups = var.self_managed_node_groups
  fargate_profiles         = var.fargate_profiles
}
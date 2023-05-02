# AWS EKS
module "eks" {
  source          = "../../../modules/aws/eks"
  profile         = var.profile
  tags            = local.tags
  name            = module.vpc.eks_cluster_name
  node_selector   = var.eks.node_selector
  kubeconfig_file = abspath(var.kubeconfig_file)
  vpc = {
    id                 = module.vpc.id
    private_subnet_ids = module.vpc.private_subnet_ids
    pods_subnet_ids    = module.vpc.pods_subnet_ids
  }
  eks = {
    region                                = var.region
    cluster_version                       = var.eks.cluster_version
    cluster_endpoint_private_access       = var.eks.cluster_endpoint_private_access
    cluster_endpoint_private_access_cidrs = var.eks.cluster_endpoint_private_access_cidrs
    cluster_endpoint_private_access_sg    = var.eks.cluster_endpoint_private_access_sg
    cluster_endpoint_public_access        = var.eks.cluster_endpoint_public_access
    cluster_endpoint_public_access_cidrs  = var.eks.cluster_endpoint_public_access_cidrs
    cluster_log_retention_in_days         = var.eks.cluster_log_retention_in_days
    docker_images = {
      cluster_autoscaler = local.ecr_images["${var.eks.docker_images.cluster_autoscaler.image}:${try(coalesce(var.eks.docker_images.cluster_autoscaler.tag), "")}"]
      instance_refresh   = local.ecr_images["${var.eks.docker_images.instance_refresh.image}:${try(coalesce(var.eks.docker_images.instance_refresh.tag), "")}"]
    }
    cluster_autoscaler = var.eks.cluster_autoscaler
    instance_refresh   = var.eks.instance_refresh
    encryption_keys = {
      cluster_log_kms_key_id    = local.kms_key
      cluster_encryption_config = local.kms_key
      ebs_kms_key_id            = local.kms_key
    }
    map_roles = var.eks.map_roles
    map_users = var.eks.map_users
  }
  eks_managed_node_groups  = var.eks_managed_node_groups
  self_managed_node_groups = var.self_managed_node_groups
  fargate_profiles         = var.fargate_profiles
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }

  depends_on = [module.eks]
}

locals {
  namespace = kubernetes_namespace.armonik.metadata[0].name
}

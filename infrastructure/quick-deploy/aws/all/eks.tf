# AWS EKS
module "eks" {
  source        = "../../../modules/aws/eks"
  profile       = var.profile
  tags          = local.tags
  name          = module.vpc.eks_cluster_name
  node_selector = var.eks.cluster_autoscaler.node_selector
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
      cluster_autoscaler = local.ecr_images["${var.eks.docker_images.cluster_autoscaler.image}:${var.eks.docker_images.cluster_autoscaler.tag}"]
      instance_refresh   = local.ecr_images["${var.eks.docker_images.instance_refresh.image}:${var.eks.docker_images.instance_refresh.tag}"]
    }
    cluster_autoscaler = var.eks.cluster_autoscaler
    encryption_keys = {
      cluster_log_kms_key_id    = local.kms_key
      cluster_encryption_config = local.kms_key
      ebs_kms_key_id            = local.kms_key
    }
    map_roles = var.eks.map_roles
    map_users = var.eks.map_users
  }
  eks_operational_worker_groups = var.eks_operational_worker_groups
  eks_worker_groups             = var.eks_worker_groups
}

resource "null_resource" "eks_namespace" {
  triggers = {
    namespace = var.namespace
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${self.triggers.namespace}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete namespace ${self.triggers.namespace}"
  }

  depends_on = [module.eks]
}

locals {
  namespace = null_resource.eks_namespace.triggers.namespace
}

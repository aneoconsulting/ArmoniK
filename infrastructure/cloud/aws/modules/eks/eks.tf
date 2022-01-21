module "eks" {
  source                                 = "terraform-aws-modules/eks/aws"
  version                                = "18.2.1"
  cluster_name                           = var.cluster_name
  cluster_version                        = var.eks.version
  vpc_id                                 = var.eks.vpc.vpc_id
  subnet_ids                             = var.eks.vpc.private_subnets
  cloudwatch_log_group_kms_key_id        = var.eks.encryption_keys_arn.cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.eks.cloudwatch_log_group_retention_in_days
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access        = var.eks.enable_private_subnet
  create_cloudwatch_log_group            = true
  cluster_endpoint_public_access         = var.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs   = var.eks.cluster_endpoint_public_access_cidrs
  # will recreate your worker nodes without draining them first
  //instance_refresh_enabled               = true
  # Determines whether to create an OpenID Connect Provider for EKS to enable IRSA
  //enable_irsa                            = true

  cluster_addons = {
    coredns    = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni    = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [
    {
      provider_key_arn = var.eks.encryption_keys_arn.secrets
      resources        = ["secrets"]
    }
  ]

  /*cluster_security_group_additional_rules = {
    admin_access = {
      description = "Admin ingress to Kubernetes API"
      cidr_blocks = [var.eks.vpc.vpc_cidr_block]
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
    }
  }*/

  tags = local.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
  tags = local.tags
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

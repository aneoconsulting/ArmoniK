module "eks" {
  source           = "terraform-aws-modules/eks/aws"
  version          = "18.2.1"
  cluster_name     = var.cluster_name
  cluster_version  = var.eks.version
  # Controls if EKS resources should be created (affects nearly all resources)
  create           = true
  prefix_separator = "-"

  ##### Network #####
  vpc_id                               = var.eks.vpc.vpc_id
  subnet_ids                           = var.eks.vpc.private_subnets
  cluster_endpoint_private_access      = var.eks.enable_private_subnet
  cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
  cluster_service_ipv4_cidr            = "10.100.0.0/16"

  ##### IPv6 #####
  create_cni_ipv6_iam_policy = false

  ##### Logs #####
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_kms_key_id        = var.eks.encryption_keys_arn.cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.eks.cloudwatch_log_group_retention_in_days
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  ##### Cluster security groups #####
  create_cluster_security_group           = true
  cluster_security_group_name             = "${var.cluster_name}-cluster-sg"
  cluster_security_group_description      = "EKS cluster security group"
  # Required if `create_cluster_security_group=false`
  cluster_security_group_id               = ""
  cluster_additional_security_group_ids   = []
  cluster_security_group_additional_rules = {}
  cluster_security_group_tags             = ""
  cluster_security_group_use_name_prefix  = ""

  ##### Node security group #####
  create_node_security_group           = true
  node_security_group_name             = "${var.cluster_name}-node-sg"
  node_security_group_description      = "EKS node shared security group"
  node_security_group_id               = ""
  # Determines whether node security group name (`node_security_group_name`) is used as a prefix
  node_security_group_use_name_prefix  = ""
  node_security_group_additional_rules = {}

  ##### Config #####
  cluster_encryption_config = [
    {
      provider_key_arn = var.eks.encryption_keys_arn.secrets
      resources        = ["secrets"]
    }
  ]
  # Create, update, and delete timeout configurations for the cluster
  cluster_timeouts          = {}
  cluster_addons            = {}

  ##### IAM #####
  cluster_identity_providers   = {}
  create_iam_role              = true
  iam_role_use_name_prefix     = true
  iam_role_additional_policies = []

  ##### OpenID Connect Provider for EKS to enable IRSA #####
  enable_irsa              = false
  openid_connect_audiences = []

  ##### Tags #####
  cluster_tags             = { cluster = var.cluster_name }
  iam_role_tags            = { cluster = var.cluster_name }
  node_security_group_tags = { cluster = var.cluster_name }
  tags                     = local.tags

  ##### Managed node groups #####
  eks_managed_node_group_defaults = {}

  ##### Self managed groups #####
  self_managed_node_group_defaults = {}
  self_managed_node_groups         = {}

  ##### Fargate profiles #####
  fargate_profile_defaults = {}
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
  tags = local.tags
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

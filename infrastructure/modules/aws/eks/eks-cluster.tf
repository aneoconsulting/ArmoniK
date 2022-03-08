module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  create_eks      = true
  cluster_name    = var.name
  cluster_version = var.eks.cluster_version

  # VPC
  subnets = var.vpc.private_subnet_ids
  vpc_id  = var.vpc.id

  # KUBECONFIG
  kubeconfig_name                           = "kubeconfig-${var.name}"
  write_kubeconfig                          = true
  kubeconfig_output_path                    = "${path.root}/generated/eks/kubeconfig-${var.name}"
  kubeconfig_file_permission                = "0600"
  kubeconfig_api_version                    = "client.authentication.k8s.io/v1alpha1"
  kubeconfig_aws_authenticator_command      = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "--region",
    local.region,
    "eks",
    "get-token",
    "--cluster-name",
    var.name
  ]

  # Private cluster
  cluster_endpoint_private_access                = var.eks.cluster_endpoint_private_access
  cluster_create_endpoint_private_access_sg_rule = var.eks.cluster_endpoint_private_access
  cluster_endpoint_private_access_cidrs          = var.eks.cluster_endpoint_private_access_cidrs
  cluster_endpoint_private_access_sg             = var.eks.cluster_endpoint_private_access_sg

  # Public cluster
  cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs

  # Cluster parameters
  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_kms_key_id        = var.eks.encryption_keys.cluster_log_kms_key_id
  cluster_log_retention_in_days = var.eks.cluster_log_retention_in_days
  cluster_create_security_group = true
  cluster_encryption_config     = [
    {
      provider_key_arn = var.eks.encryption_keys.cluster_encryption_config
      resources        = ["secrets"]
    }
  ]

  # Tags
  tags         = merge(local.tags, { name = var.name })
  cluster_tags = merge(local.tags, { name = var.name, component = "Cluster resources" })

  # IAM
  map_roles = [
    {
      rolearn  = module.eks.worker_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]
  map_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.arn}:user/admin"
      username = "admin"
      groups   = ["system:masters", "system:bootstrappers", "system:nodes"]
    }
  ]

  # Worker groups
  worker_groups_launch_template = local.eks_worker_group

  /*
    # Required
    cluster_service_ipv4_cidr             = ""
    fargate_pod_execution_role_name       = ""
    permissions_boundary                  = ""

    # Optional
    attach_worker_cni_policy                           = true
    aws_auth_additional_labels                         = {}
    cluster_egress_cidrs                               = ["0.0.0.0/0"]
    cluster_iam_role_name                              = ""
    cluster_security_group_id                          = ""
    cluster_create_timeout                             = "30m"
    cluster_delete_timeout                             = "15m"
    cluster_update_timeout                             = "60m"
    create_fargate_pod_execution_role                  = true
    default_platform                                   = "linux"
    eks_oidc_root_ca_thumbprint                        = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    enable_irsa                                        = false
    fargate_profiles                                   = {}
    fargate_subnets                                    = []
    iam_path                                           = "/"
    kubeconfig_aws_authenticator_additional_args       = []
    kubeconfig_aws_authenticator_env_variables         = {}
    kubeconfig_output_path                             = "./"
    manage_aws_auth                                    = true
    manage_cluster_iam_resources                       = true
    manage_worker_iam_resources                        = true
    map_accounts                                       = []
    node_groups                                        = {}
    node_groups_defaults                               = {}
    openid_connect_audiences                           = []
    wait_for_cluster_timeout                           = 300
    worker_additional_security_group_ids               = []
    worker_ami_name_filter                             = ""
    worker_ami_name_filter_windows                     = ""
    worker_ami_owner_id                                = "amazon"
    worker_ami_owner_id_windows                        = "amazon"
    worker_create_cluster_primary_security_group_rules = false
    worker_create_initial_lifecycle_hooks              = false
    worker_create_security_group                       = true
    worker_groups                                      = []
    worker_security_group_id                           = ""
    worker_sg_ingress_from_port                        = 1025
    workers_additional_policies                        = []
    workers_egress_cidrs                               = ["0.0.0.0/0"]
    workers_group_defaults                             = {}
    workers_role_name                                  = ""
  */
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}


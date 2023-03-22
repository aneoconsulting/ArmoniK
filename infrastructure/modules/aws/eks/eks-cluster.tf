locals {
  cluster_iam_role_arn = module.eks.cluster_iam_role_arn
}
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.10.0"
  create          = true
  cluster_name    = var.name
  cluster_version = var.eks.cluster_version

  # VPC
  subnet_ids = var.vpc.private_subnet_ids
  vpc_id     = var.vpc.id

  create_aws_auth_configmap = true
  # Needed to add self managed node group configuration.
  # => kubectl get cm aws-auth -n kube-system -o yaml
  manage_aws_auth_configmap = true

  # Private cluster
  cluster_endpoint_private_access = var.eks.cluster_endpoint_private_access

  # Public cluster
  cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs

  # Cluster parameters
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_kms_key_id        = var.eks.encryption_keys.cluster_log_kms_key_id
  cloudwatch_log_group_retention_in_days = var.eks.cluster_log_retention_in_days
  create_cluster_security_group          = true
  cluster_encryption_config = {
    provider_key_arn = var.eks.encryption_keys.cluster_encryption_config
    resources        = ["secrets"]
  }

  # Tags
  #TODO: Arnaud.L tags must be added back - pb with depends_on on module 'bug'
  tags         = local.tags
  cluster_tags = local.tags

  # IAM
  # used to allow other users to interact with our cluster
  aws_auth_roles = concat([
    {
      rolearn  = local.cluster_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ], var.eks.map_roles)
  aws_auth_users = concat([
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.arn}:user/admin"
      username = "admin"
      groups   = ["system:masters", "system:bootstrappers", "system:nodes"]
    }
  ], var.eks.map_users)

  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.name}" : "owned"
      "aws-node-termination-handler/managed" : true
    }
  }

  # it replaces previously created role in iam.tf 
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    # "eks-vpc-resource-access" = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  # Worker groups
  self_managed_node_groups = local.eks_worker_group
  /*
  module input from doc : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#optional-inputs
  variables from module code : https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  sample usages : https://github.com/Jitsusama/example-terraform-eks-mixed-os-cluster/blob/main/cluster.tf#L91
                  https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0



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

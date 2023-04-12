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

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node port 80 ingress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      self        = true
    }
  }

  cluster_encryption_config = {
    provider_key_arn = var.eks.encryption_keys.cluster_encryption_config
    resources        = ["secrets"]
  }

  # Tags
  tags         = local.tags
  cluster_tags = local.tags

  # IAM
  # used to allow other users to interact with our cluster
  aws_auth_roles = var.eks.map_roles
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
    # it replaces previously created role in iam.tf
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  # Worker groups
  # module input from doc : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#optional-inputs
  # variables from module code : https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  # sample usages : https://github.com/Jitsusama/example-terraform-eks-mixed-os-cluster/blob/main/cluster.tf#L91
  #                 https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  self_managed_node_groups = local.eks_worker_group
}

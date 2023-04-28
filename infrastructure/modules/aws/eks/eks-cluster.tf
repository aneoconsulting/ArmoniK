module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.10.0"
  create          = true
  cluster_name    = var.name
  cluster_version = var.eks.cluster_version

  # VPC
  subnet_ids = var.vpc.private_subnet_ids
  vpc_id     = var.vpc.id

  create_aws_auth_configmap = !(can(coalesce(var.eks_managed_node_groups)) && can(coalesce(var.fargate_profiles)))
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

  # List of EKS managed node groups
  eks_managed_node_group_defaults = {
    enable_monitoring = true
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }
    # The sysctls fs.inotify.max_user_instances defines user limits on the number of inotify resources.
    # In the context of a Kubernetes cluster, if these limits are reached, you may experience processes
    # failing with error messages related to the limits, and it would exhibit as failing Pods with inotify
    # related errors in the Pod logs.
    post_bootstrap_user_data = <<-EOT
        echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
      EOT
  }

  # List of self managed node groups
  self_managed_node_group_defaults = {
    enable_monitoring      = true
    tags                   = local.tags
    autoscaling_group_tags = local.autoscaling_group_tags
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }
    # The sysctls fs.inotify.max_user_instances defines user limits on the number of inotify resources.
    # In the context of a Kubernetes cluster, if these limits are reached, you may experience processes
    # failing with error messages related to the limits, and it would exhibit as failing Pods with inotify
    # related errors in the Pod logs.
    post_bootstrap_user_data = <<-EOT
        echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
      EOT
  }

  # List of fargate profiles
  fargate_profile_defaults = {
    tags = local.tags
  }

  # Worker groups
  # module input from doc : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#optional-inputs
  # variables from module code : https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  # sample usages : https://github.com/Jitsusama/example-terraform-eks-mixed-os-cluster/blob/main/cluster.tf#L91
  #                 https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  eks_managed_node_groups  = local.eks_managed_node_groups
  self_managed_node_groups = local.self_managed_node_groups
  fargate_profiles         = local.fargate_profiles
}

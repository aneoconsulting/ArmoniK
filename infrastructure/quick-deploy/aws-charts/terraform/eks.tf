locals {
  # Many pods per node, each watched by fluent-bit: the AL2023 default of 128 inotify instances
  # runs out and pods fail with "too many open files".
  node_sysctl_user_data = <<-EOT
    #!/bin/bash
    echo fs.inotify.max_user_instances=8192 > /etc/sysctl.d/99-armonik.conf
    sysctl --system
  EOT

  node_iam_policies = {
    AmazonSSMManagedInstanceCore = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    EcrPullThroughCache          = aws_iam_policy.ecr_pull_through_cache.arn
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.26"

  name               = local.name
  kubernetes_version = var.eks.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access       = var.eks.endpoint_public_access
  endpoint_public_access_cidrs = var.eks.endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    for i, arn in var.eks.admin_principal_arns : "admin-${i}" => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  create_kms_key    = false
  encryption_config = { provider_key_arn = module.kms.key_arn }

  enabled_log_types                      = var.eks.log_types
  cloudwatch_log_group_retention_in_days = var.eks.log_retention_in_days
  cloudwatch_log_group_kms_key_id        = module.kms.key_arn

  addons = {
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    # Tolerates CriticalAddonsOnly by default, so it lands on the system nodes
    coredns = {}
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = module.ebs_csi_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  # The recommended rules only open the ephemeral ports between nodes, while Seq, nginx and the
  # ArmoniK components listen below 1024 or on arbitrary ports.
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node, all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }

  # Runs Karpenter and CoreDNS only, everything else goes to the Karpenter node pools
  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.eks.system_instance_types
      min_size       = var.eks.system_node_group_size
      max_size       = var.eks.system_node_group_size + 1
      desired_size   = var.eks.system_node_group_size

      labels = {
        "armonik.aneo.fr/node-group" = "system"
      }
      taints = {
        critical = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      cloudinit_pre_nodeadm = [{
        content_type = "text/x-shellscript"
        content      = local.node_sysctl_user_data
      }]

      iam_role_additional_policies = local.node_iam_policies
    }
  }
}

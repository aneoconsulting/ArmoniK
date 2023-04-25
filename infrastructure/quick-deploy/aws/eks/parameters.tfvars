# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# Tags
tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}

# Node selector
node_selector = { "grid/type" = "Operator" }

# AWS EKS
eks = {
  name                                  = "armonik-eks"
  cluster_version                       = "1.25"
  cluster_endpoint_private_access       = true # vpc.enable_private_subnet
  cluster_endpoint_private_access_cidrs = []
  cluster_endpoint_private_access_sg    = []
  cluster_endpoint_public_access        = false
  cluster_endpoint_public_access_cidrs  = ["0.0.0.0/0"]
  cluster_log_retention_in_days         = 30
  docker_images = {
    cluster_autoscaler = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/cluster-autoscaler"
      tag   = "v1.23.0"
    }
    instance_refresh = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-node-termination-handler"
      tag   = "v1.19.0"
    }
  }
  cluster_autoscaler = {
    expander                              = "random" # random, most-pods, least-waste, price, priority
    scale_down_enabled                    = true
    min_replica_count                     = 0
    scale_down_utilization_threshold      = 0.5
    scale_down_non_empty_candidates_count = 30
    max_node_provision_time               = "15m0s"
    scan_interval                         = "10s"
    scale_down_delay_after_add            = "2m"
    scale_down_delay_after_delete         = "0s"
    scale_down_delay_after_failure        = "3m"
    scale_down_unneeded_time              = "2m"
    skip_nodes_with_system_pods           = true
    version                               = "9.24.0"
    repository                            = "https://kubernetes.github.io/autoscaler"
    namespace                             = "kube-system"
  }
  instance_refresh = {
    namespace  = "kube-system"
    repository = "https://aws.github.io/eks-charts"
    version    = "0.21.0"
  }
  encryption_keys = {
    cluster_log_kms_key_id    = ""
    cluster_encryption_config = ""
    ebs_kms_key_id            = ""
  }
  map_roles = []
  map_users = []
}

# List of EKS managed node groups
eks_managed_node_groups = {
  opt = {
    name                        = "eks_opt"
    launch_template_description = "Node group for operational pods"
    ami_type                    = "AL2_x86_64"
    instance_types = [
      "m5.large",
      "m5.xlarge",
      "m5.2xlarge",
      "m5.4xlarge",
      "m5.8xlarge",
      "m5.12xlarge",
      "m5d.large",
      "m5d.xlarge",
      "m5d.2xlarge",
      "m5d.4xlarge",
      "m5d.8xlarge",
      "m5d.12xlarge"
    ]
    capacity_type = "ON_DEMAND"
    min_size      = 1
    desired_size  = 1
    max_size      = 5
    labels = {
      "grid/type"                    = "Operator"
      "node.kubernetes.io/lifecycle" = "ondemand"
    }
    taints = {
      dedicated = {
        key    = "grid/type"
        value  = "Operator"
        effect = "NO_SCHEDULE"
      }
    }
    bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=ondemand'"
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# List of self managed node groups
self_managed_node_groups = {
  spot = {
    name                        = "self_spot"
    launch_template_description = "Worker nodes in SPOT"
    instance_type               = "c5.24xlarge"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 2700
    force_delete                = true
    force_delete_warm_pool      = true
    instance_market_options = {
      market_type = "spot"
    }
    bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# List of fargate profiles
fargate_profiles = {}

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

# Operational node groups for EKS
eks_operational_worker_groups = {
  eks_operational_worker_groups = {
    name                                     = "operational-worker"
    spot_allocation_strategy                 = "capacity-optimized"
    instance_type                            = "c5.4xlarge"
    spot_instance_pools                      = 0
    asg_min_size                             = 1
    asg_max_size                             = 5
    asg_desired_capacity                     = 1
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 100
    bootstrap_extra_args                     = "--kubelet-extra-args '--node-labels=grid/type=Operator --register-with-taints=grid/type=Operator:NoSchedule'"
  }
}

# EKS worker groups
eks_worker_groups = {
  linux = {
    name                                     = "worker-c5.4xlarge-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    instance_type                            = "c5.4xlarge"
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 1000
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  }
  ,
      linux_mixed = {
      name = "mixed"
      min_size     = 1
      max_size     = 5
      desired_size = 2
      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 20
          spot_allocation_strategy                 = "capacity-optimized"
        }
        override = [
          {
            instance_type     = "c5.4xlarge"
            weighted_capacity = "1"
          },
          {
            instance_type     = "c5.2xlarge"
            weighted_capacity = "2"
          },
        ]
      }
    }
}

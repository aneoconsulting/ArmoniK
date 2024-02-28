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
node_selector = { service = "monitoring" }

# AWS EKS
eks = {
  name                                  = "armonik-eks"
  cluster_version                       = "1.29"
  cluster_endpoint_private_access       = false # vpc.enable_private_subnet
  cluster_endpoint_private_access_cidrs = []
  cluster_endpoint_private_access_sg    = []
  cluster_endpoint_public_access        = true
  cluster_endpoint_public_access_cidrs  = ["0.0.0.0/0"]
  cluster_log_retention_in_days         = 30
  docker_images                         = {
    cluster_autoscaler = {
      image = "cluster-autoscaler"
      tag   = "v1.29.0"
    }
    instance_refresh = {
      image = "aws-node-termination-handler"
      tag   = "v1.19.0"
    }
    efs_csi = {
      image = "aws-efs-csi-driver"
      tag   = "v1.5.1"
    }
    efs_csi_liveness_probe = {
      image = "livenessprobe"
      tag   = "v2.9.0-eks-1-22-19"
    }
    efs_csi_node_driver_registrar = {
      image = "node-driver-registrar"
      tag   = "v2.7.0-eks-1-22-19"
    }
    efs_csi_external_provisioner = {
      image = "external-provisioner"
      tag   = "v3.4.0-eks-1-22-19"
    }
  }
  cluster_autoscaler = {
    expander                              = "least-waste" # random, most-pods, least-waste, price, priority
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
    version                               = "9.35.0"
    repository                            = "https://kubernetes.github.io/autoscaler"
    namespace                             = "kube-system"
  }
  efs_csi = {
    repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
    version    = "2.3.0"
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
  # Default node group for workers of ArmoniK
  /*workers = {
    name                        = "workers"
    launch_template_description = "Node group for ArmoniK Compute-plane pods"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 1000
    labels = {
      service                        = "workers"
      "node.kubernetes.io/lifecycle" = "spot"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "workers"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }*/
  /*default = {
    name                        = "default"
    launch_template_description = "Node group for ArmoniK Compute-plane pods"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 1000
    labels                      = {
      service                        = "default"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "default"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  htcmock = {
    name                        = "htcmock"
    launch_template_description = "Node group for ArmoniK Compute-plane pods"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 1000
    labels                      = {
      service                        = "htcmock"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "htcmock"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  bench = {
    name                        = "bench"
    launch_template_description = "Node group for ArmoniK Compute-plane pods"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 1000
    labels                      = {
      service                        = "bench"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "bench"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  stream = {
    name                        = "stream"
    launch_template_description = "Node group for ArmoniK Compute-plane pods"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 1000
    labels                      = {
      service                        = "stream"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "stream"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
*/
  # Node group for metrics: Metrics exporter and Prometheus
  metrics = {
    name                        = "metrics"
    launch_template_description = "Node group for metrics: Metrics exporter and Prometheus"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "ON_DEMAND"
    min_size                    = 1
    desired_size                = 1
    max_size                    = 5
    labels                      = {
      service                        = "metrics"
      "node.kubernetes.io/lifecycle" = "ondemand"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "metrics"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  # Node group for ArmoniK control-plane: control-plane and Ingress
  control_plane = {
    name                        = "control-plane"
    launch_template_description = "Node group for ArmoniK Control-plane and Ingress"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "ON_DEMAND"
    min_size                    = 1
    desired_size                = 1
    max_size                    = 10
    labels                      = {
      service                        = "control-plane"
      "node.kubernetes.io/lifecycle" = "ondemand"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "control-plane"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  # Node group for monitoring: metrics server, keda, seq, grafana, cluster-autoscaler, coreDNS, termination handler
  monitoring = {
    name                        = "monitoring"
    launch_template_description = "Node group for monitoring"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    capacity_type               = "ON_DEMAND"
    min_size                    = 1
    desired_size                = 1
    max_size                    = 5
    labels                      = {
      service                        = "monitoring"
      "node.kubernetes.io/lifecycle" = "ondemand"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "monitoring"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  # Node group for data-plane
  # state_database, inner_storage, task_queue
  state_database = {
    name                        = "mongodb"
    launch_template_description = "Node group for MongoDB"
    ami_type                    = "AL2_x86_64"
    instance_types              = ["c5.large"]
    use_custom_launch_template  = true
    block_device_mappings       = {
      xvda = {
        device_name = "/dev/xvda"
        ebs         = {
          volume_size           = 75
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = null
          kms_key_id            = null
          delete_on_termination = true
        }
      }
    }
    capacity_type = "ON_DEMAND"
    min_size      = 1
    desired_size  = 1
    max_size      = 10
    labels        = {
      service                        = "state-database"
      "node.kubernetes.io/lifecycle" = "ondemand"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "state-database"
        effect = "NO_SCHEDULE"
      }
    }
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# List of self managed node groups
self_managed_node_groups = {
  default = {
    name                         = "default"
    launch_template_description  = "Node group for default"
    force_delete                 = true
    force_delete_warm_pool       = true
    bootstrap_extra_args         = "--kubelet-extra-args '--node-labels=service=default --register-with-taints=service=default:NoSchedule'"
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    min_size              = 0
    desired_size          = 0
    max_size              = 1000
    instance_type         = null
    instance_requirements = {
      allowed_instance_types = ["t*", "m*", "c*"]
      cpu_manufacturers      = ["intel"]
      instance_generations   = ["current", "previous"]
      vcpu_count             = {
        min = 2
      }
      memory_mib = {
        min = 1000
      }
    }
    use_mixed_instances_policy = true
    mixed_instances_policy     = {
      instances_distribution = {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
        on_demand_allocation_strategy            = "lowest-price"
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = null
        spot_max_price                           = null
      }
    }
    labels = {
      service                        = "default"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "default"
        effect = "NO_SCHEDULE"
      }
    }
  }
  htcmock = {
    name                         = "htcmock"
    launch_template_description  = "Node group for htcmock"
    force_delete                 = true
    force_delete_warm_pool       = true
    bootstrap_extra_args         = "--kubelet-extra-args '--node-labels=service=htcmock --register-with-taints=service=htcmock:NoSchedule'"
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    min_size              = 0
    desired_size          = 0
    max_size              = 1000
    instance_type         = null
    instance_requirements = {
      allowed_instance_types = ["t*", "m*", "c*"]
      cpu_manufacturers      = ["intel"]
      instance_generations   = ["current", "previous"]
      vcpu_count             = {
        min = 2
      }
      memory_mib = {
        min = 1000
      }
    }
    use_mixed_instances_policy = true
    mixed_instances_policy     = {
      instances_distribution = {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
        on_demand_allocation_strategy            = "lowest-price"
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = null
        spot_max_price                           = null
      }
    }
    labels = {
      service                        = "htcmock"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "htcmock"
        effect = "NO_SCHEDULE"
      }
    }
  }
  bench = {
    name                         = "bench"
    launch_template_description  = "Node group for bench"
    force_delete                 = true
    force_delete_warm_pool       = true
    bootstrap_extra_args         = "--kubelet-extra-args '--node-labels=service=bench --register-with-taints=service=bench:NoSchedule'"
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    min_size              = 0
    desired_size          = 0
    max_size              = 1000
    instance_type         = null
    instance_requirements = {
      allowed_instance_types = ["t*", "m*", "c*"]
      cpu_manufacturers      = ["intel"]
      instance_generations   = ["current", "previous"]
      vcpu_count             = {
        min = 2
      }
      memory_mib = {
        min = 1000
      }
    }
    use_mixed_instances_policy = true
    mixed_instances_policy     = {
      instances_distribution = {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
        on_demand_allocation_strategy            = "lowest-price"
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = null
        spot_max_price                           = null
      }
    }
    labels = {
      service                        = "bench"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "bench"
        effect = "NO_SCHEDULE"
      }
    }
  }
  stream = {
    name                         = "stream"
    launch_template_description  = "Node group for stream"
    force_delete                 = true
    force_delete_warm_pool       = true
    bootstrap_extra_args         = "--kubelet-extra-args '--node-labels=service=stream --register-with-taints=service=stream:NoSchedule'"
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    min_size              = 0
    desired_size          = 0
    max_size              = 1000
    instance_type         = null
    instance_requirements = {
      allowed_instance_types = ["t*", "m*", "c*"]
      cpu_manufacturers      = ["intel"]
      instance_generations   = ["current", "previous"]
      vcpu_count             = {
        min = 2
      }
      memory_mib = {
        min = 1000
      }
    }
    use_mixed_instances_policy = true
    mixed_instances_policy     = {
      instances_distribution = {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
        on_demand_allocation_strategy            = "lowest-price"
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = null
        spot_max_price                           = null
      }
    }
    labels = {
      service                        = "stream"
    }
    taints = {
      dedicated = {
        key    = "service"
        value  = "stream"
        effect = "NO_SCHEDULE"
      }
    }
  }
  others = {
    name                        = "others"
    launch_template_description = "Node group for others"
    instance_type               = "c5.large"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 5
    force_delete                = true
    force_delete_warm_pool      = true
    instance_market_options     = {
      market_type = "spot"
    }
    bootstrap_extra_args         = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  others_mixed = {
    name                        = "others-mixed"
    launch_template_description = "Mixed On demand and SPOT instances for other pods"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 5
    use_mixed_instances_policy  = true
    mixed_instances_policy      = {
      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20 # 20% On-Demand Instances, 80% Spot Instances
      spot_allocation_strategy                 = "price-capacity-optimized"
      spot_instance_pools                      = null
      spot_max_price                           = null
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
    iam_role_use_name_prefix     = false
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# List of fargate profiles
fargate_profiles = {}

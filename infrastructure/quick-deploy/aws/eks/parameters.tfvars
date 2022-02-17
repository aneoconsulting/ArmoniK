# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# VPC info
vpc = {
  id                     = ""
  cidr_block             = ""
  private_subnet_ids     = []
  pod_cidr_block_private = []
  pods_subnet_ids        = []
}

# shared storage
s3_fs = {
  name       = ""
  kms_key_id = ""
  host_path  = "/data"
}

# AWS EKS
eks = {
  name                                 = "armonik-eks"
  cluster_version                      = "1.21"
  cluster_endpoint_private_access      = true # vpc.enable_private_subnet
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_log_retention_in_days        = 30
  docker_images                        = {
    cluster_autoscaler = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/cluster-autoscaler"
      tag   = "v1.23.0"
    }
    instance_refresh   = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-node-termination-handler"
      tag   = "v1.15.0"
    }
  }
  encryption_keys                      = {
    cluster_log_kms_key_id    = ""
    cluster_encryption_config = ""
    ebs_kms_key_id            = ""
  }
}

# EKS worker groups
eks_worker_groups = [
  {
    name                                     = "worker-small-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
    tags                                     = []
  },
  {
    name                                     = "worker-2xmedium-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["m5.2xlarge", "m5d.2xlarge", "m5a.2xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  },
  {
    name                                     = "worker-4xmedium-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["m5.4xlarge", "m5d.4xlarge", "m5a.4xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  },
  {
    name                                     = "worker-8xmedium-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["m5.8xlarge", "m5d.8xlarge", "m5a.8xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  },
  {
    name                                     = "worker-small-ondemand"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 100
    kubelet_extra_args                       = "--node-labels=lifecycle=OnDemand --register-with-taints=lifecycle=OnDemand:NoSchedule"
  }
]

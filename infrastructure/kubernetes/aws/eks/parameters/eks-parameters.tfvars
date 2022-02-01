# S3 bucket as Filesystem
s3fs_bucket = {
  name             = "s3fs"
  kms_key_id       = ""
  shared_host_path = "/data"
  tags             = {}
}

# Encryption at rest
encryption_keys = {
  cluster_log_kms_key_id    = ""
  cluster_encryption_config = ""
  ebs_kms_key_id            = ""
}

# EKS
eks = {
  cluster_version                      = "1.21"
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_log_retention_in_days        = 30
  docker_registry                      = ""
  docker_images                        = {
    cluster_autoscaler = {
      #image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/cluster-autoscaler"
      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag   = "v1.21.0"
    }
    instance_refresh   = {
      #image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-node-termination-handler"
      image = "amazon/aws-node-termination-handler"
      tag   = "v1.10.0"
    }
  }
}

# EKS worker groups
eks_worker_groups = [
  {
    name                                     = "worker-small-spot"
    override_instance_types                  = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  },
  {
    name                                     = "worker-2xmedium-spot"
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
    override_instance_types                  = ["m5.8xlarge", "m5d.8xlarge", "m5a.8xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  },
  {
    name                                     = "worker-on-demand"
    override_instance_types                  = [
      "m5.xlarge",
      "m5d.xlarge",
      "m5a.xlarge",
      "m5.2xlarge",
      "m5d.2xlarge",
      "m5a.2xlarge",
      "m5.4xlarge",
      "m5d.4xlarge",
      "m5a.4xlarge",
      "m5.8xlarge",
      "m5d.8xlarge",
      "m5a.8xlarge"
    ]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 20
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 100
    kubelet_extra_args                       = "--node-labels=node.kubernetes.io/lifecycle=normal"
    k8s_labels                               = { "node.kubernetes.io/lifecycle" = "normal" }
  }
]

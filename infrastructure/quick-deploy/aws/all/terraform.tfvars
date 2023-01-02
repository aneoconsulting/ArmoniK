# AWS EKS
eks = {
  cluster_version = "1.22"
  cluster_autoscaler = {
    node_selector = { "grid/type" = "Operator" }
  }
  docker_images = {
    cluster_autoscaler = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/cluster-autoscaler"
      tag   = "v1.23.0"
    }
    instance_refresh = {
      image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-node-termination-handler"
      tag   = "v1.15.0"
    }
  }
}

# Operational node groups for EKS
eks_operational_worker_groups = [
  {
    name                                     = "operational-worker-ondemand"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["c5.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 1
    asg_max_size                             = 5
    asg_desired_capacity                     = 1
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 100
    kubelet_extra_args                       = "--node-labels=grid/type=Operator --register-with-taints=grid/type=Operator:NoSchedule"
  }
]

# EKS worker groups
eks_worker_groups = [
  {
    name                                     = "worker-c5.4xlarge-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["c5.4xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 1000
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  }
]
metrics_server = {
  node_selector = { "grid/type" = "Operator" }
}
keda = {
  node_selector = { "grid/type" = "Operator" }
}
elasticache = {
  engine             = "redis"
  engine_version     = "6.x"
  node_type          = "cache.r4.large"
  num_cache_clusters = 2
}
mq = {
  engine_type        = "ActiveMQ"
  engine_version     = "5.16.4"
  host_instance_type = "mq.m5.xlarge"
}
mongodb = {
  image_name    = "mongo"
  image_tag     = "5.0.9"
  node_selector = { "grid/type" = "Operator" }
  persistent_volume = {
    storage_provisioner = "efs.csi.aws.com"
    resources = {
      requests = {
        storage = "5Gi"
      }
    }
  }
}
pv_efs = {
  csi_driver = {
    node_selector      = { "grid/type" = "Operator" }
    images = {
      efs_csi = {
        name = "amazon/aws-efs-csi-driver"
        tag  = "v1.4.3"
      }
      livenessprobe = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
        tag  = "v2.2.0-eks-1-18-13"
      }
      node_driver_registrar = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
        tag  = "v2.1.0-eks-1-18-13"
      }
      external_provisioner = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
        tag  = "v2.1.1-eks-1-18-13"
      }
    }
  }
}

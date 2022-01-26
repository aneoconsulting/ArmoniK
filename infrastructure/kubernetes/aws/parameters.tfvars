# EKS worker groups
eks_worker_groups = [
  {
    name                                     = "default"
    override_instance_types                  = ["m5.xlarge", "m4.xlarge", "m5d.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 1
    asg_max_size                             = 3
    asg_desired_capacity                     = 1
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 100
    spot_allocation_strategy                 = "capacity-optimized"
    kubelet_extra_args                       = "--node-labels=grid/type=Operator --register-with-taints=grid/type=Operator:NoSchedule"
  }
]
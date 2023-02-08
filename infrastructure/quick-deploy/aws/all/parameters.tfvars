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


vpc = {
  enable_private_subnet = false
}

# AWS EKS
eks = {
  cluster_version = "1.22"
  cluster_autoscaler = {
    node_selector = { "grid/type" = "Operator" }
  }
  cluster_endpoint_public_access = true
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
# Object storage
# Uncomment either the `elasticache` or the `s3_os` parameter
elasticache = {
  engine             = "redis"
  engine_version     = "6.x"
# node_type          = "cache.r4.large"
  node_type          = "cache.r4.4xlarge"
  num_cache_clusters = 2
}
s3_os = {}

mq = {
  engine_type        = "ActiveMQ"
  engine_version     = "5.16.4"
  host_instance_type = "mq.m5.xlarge"
}
mongodb = {
  node_selector = { "grid/type" = "Operator" }
  #persistent_volume = {
  #  storage_provisioner = "efs.csi.aws.com"
  #  resources = {
  #    requests = {
  #      storage = "5Gi"
  #    }
  #  }
  #}
}
pv_efs = {
  csi_driver = {
    node_selector = { "grid/type" = "Operator" }
  }
}

seq = {
  node_selector = { "grid/type" = "Operator" }
}

grafana = {
  node_selector = { "grid/type" = "Operator" }
}

node_exporter = {
  node_selector = { "grid/type" = "Operator" }
}

prometheus = {
  node_selector = { "grid/type" = "Operator" }
}

metrics_exporter = {
  node_selector = { "grid/type" = "Operator" }
}

//parition_metrics_exporter = {
//  node_selector = { "grid/type" = "Operator" }
//}

fluent_bit = {
  is_daemonset = true
}


# Logging level
logging_level = "Information"

# Parameters of control plane
control_plane = {
  limits = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests = {
    cpu    = "200m"
    memory = "500Mi"
  }
  default_partition = "default"
}

# Parameters of admin GUI
admin_gui = {
  api = {
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  app = {
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

# Parameters of the compute plane
compute_plane = {
  default = {
    # number of replicas for each deployment of compute plane
    replicas = 1
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "1000m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/armonik_worker_dll"
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
        requests = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    ]
    hpa = {
      type              = "prometheus"
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 1
      max_replica_count = 300
      behavior = {
        restore_to_original_replica_count = true
        stabilization_window_seconds      = 300
        type                              = "Percent"
        value                             = 100
        period_seconds                    = 15
      }
      triggers = [
        {
          type      = "prometheus"
          threshold = 2
        },
      ]
    }
  },
}

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  tls                  = false
  mtls                 = false
  generate_client_cert = false
}

extra_conf = {
  core = {
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
  }
}

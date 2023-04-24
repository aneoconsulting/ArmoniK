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
  cluster_version = "1.25"
  cluster_autoscaler = {
    node_selector = { "grid/type" = "Operator" }
  }
  cluster_endpoint_public_access = true
  map_roles                      = []
  map_users                      = []
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
  mixed = {
    name                        = "self_mixed"
    launch_template_description = "Mixed On demand and SPOT instances for the worker nodes in SPOT"
    min_size                    = 0
    desired_size                = 0
    max_size                    = 3
    use_mixed_instances_policy  = true
    mixed_instances_policy = {
      on_demand_allocation_strategy            = null
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
    bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# List of fargate profiles
fargate_profiles = {}

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
  node_type          = "cache.r4.large"
  num_cache_clusters = 2
}

#s3_os = {}

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
  extra_conf = {
    MongoDB__AllowInsecureTls              = true
    Serilog__MinimumLevel                  = "Information"
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
  }
}

/*parition_metrics_exporter = {
  node_selector = { "grid/type" = "Operator" }
  extra_conf    = {
    MongoDB__AllowInsecureTls           = true
    Serilog__MinimumLevel               = "Information"
    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
  }
}*/

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
  limits = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
}

#Parameters of old admin GUI
admin_old_gui = {
  api = {
    name = "admin-api"
    port = 3333
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  old = {
    name = "admin-old-gui"
    port = 1080
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  service_type       = "ClusterIP"
  replicas           = 1
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = {}
}

# Parameters of the compute plane
compute_plane = {
  # Default partition that uses the C# extension for the worker
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
        cpu    = "500m"
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
      max_replica_count = 100
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
  # Partition for the stream worker
  stream = {
    # number of replicas for each deployment of compute plane
    replicas = 1
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "500m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/armonik_core_stream_test_worker"
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
      max_replica_count = 100
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
  # Partition for the htcmock worker
  htcmock = {
    # number of replicas for each deployment of compute plane
    replicas = 1
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "500m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/armonik_core_htcmock_test_worker"
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
      max_replica_count = 100
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
  # Partition for the bench worker
  bench = {
    # number of replicas for each deployment of compute plane
    replicas = 1
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "500m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/armonik_core_bench_test_worker"
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
      max_replica_count = 100
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
    Amqp__AllowHostMismatch                    = false
    Amqp__MaxPriority                          = "10"
    Amqp__MaxRetries                           = "5"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
    MongoDB__DataRetention                     = "10.00:00:00"
    MongoDB__AllowInsecureTls                  = true
    Redis__Timeout                             = 3000
    Redis__SslHost                             = ""
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

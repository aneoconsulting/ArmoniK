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

# Operational node groups for EKS
eks_operational_worker_groups = {
  eks_operational_worker = {
    name                                     = "opt"
    spot_allocation_strategy                 = "capacity-optimized"
    instance_type                            = "c5.4xlarge"
    spot_instance_pools                      = 0
    min_size                                 = 1
    max_size                                 = 5
    desired_size                             = 1
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 100
    bootstrap_extra_args                     = "--kubelet-extra-args '--node-labels=grid/type=Operator --register-with-taints=grid/type=Operator:NoSchedule'"
  }
}

# EKS worker groups
eks_worker_groups = {
  linux = {
    name                                     = "spot"
    spot_allocation_strategy                 = "capacity-optimized"
    instance_type                            = "c5.24xlarge"
    spot_instance_pools                      = 0
    min_size                                 = 0
    max_size                                 = 1000
    desired_size                             = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
    iam_role_name                            = "self-managed-node-group-worker-linux"
    iam_role_description                     = "self-managed-node-group-worker-linux"
  },
  linux_mixed = {
    name                       = "mixed"
    min_size                   = 1
    max_size                   = 5
    desired_size               = 2
    bootstrap_extra_args       = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
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
    Components__QueueAdaptorSettings__AdapterAbsolutePath = "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"
    Amqp__AllowHostMismatch                               = false
    Amqp__MaxPriority                                     = "10"
    Amqp__MaxRetries                                      = "5"
    Amqp__QueueStorage__LockRefreshPeriodicity            = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity                   = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension              = "00:02:00"
    MongoDB__TableStorage__PollingDelayMin                = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax                = "00:00:10"
    MongoDB__TableStorage__PollingDelay                   = "00:00:01"
    MongoDB__DataRetention                                = "10.00:00:00"
    MongoDB__AllowInsecureTls                             = true
    Redis__Timeout                                        = 3000
    Redis__SslHost                                        = ""
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

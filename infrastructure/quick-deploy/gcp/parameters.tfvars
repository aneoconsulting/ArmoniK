# GKE
gke = {
  enable_public_gke_access = true
  enable_gke_autopilot     = false
  # Autoscaling bounds over all the zones of each pool (min_count and max_count would be per zone).
  # initial_node_count is per zone
  node_pools = {
    workers = {
      machine_type       = "e2-standard-8"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 0
      total_max_count    = 1000
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = true
      labels             = { service = "workers" }
      taints = [
        {
          key    = "service"
          value  = "workers"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    metrics = {
      machine_type       = "e2-medium"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 1
      total_max_count    = 5
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = false
      labels             = { service = "metrics" }
      taints = [
        {
          key    = "service"
          value  = "metrics"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    control-plane = {
      machine_type       = "e2-medium"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 1
      total_max_count    = 10
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = false
      labels             = { service = "control-plane" }
      taints = [
        {
          key    = "service"
          value  = "control-plane"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    monitoring = {
      machine_type       = "e2-medium"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 1
      total_max_count    = 5
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = false
      labels             = { service = "monitoring" }
      taints = [
        {
          key    = "service"
          value  = "monitoring"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    state-database = {
      machine_type       = "e2-medium"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 1
      total_max_count    = 10
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = false
      labels             = { service = "state-database" }
      taints = [
        {
          key    = "service"
          value  = "state-database"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    others = {
      machine_type       = "e2-medium"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 0
      total_min_count    = 0
      total_max_count    = 100
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = true
      labels             = { service = "others" }
    }
  }
}

kms = {
  key_ring   = "armonik-europe-west1"
  crypto_key = "armonik-europe-west1"
}

# Logging level
logging_level = "Information"

keda = {
  node_selector = { service = "monitoring" }
}

# activemq = {
#   node_selector = { service = "state-database" }
#   limits = {
#     cpu = "4000m"
#     memory = "16Gi"
#   }
#   requests = {
#     cpu = "4000m"
#     memory = "16Gi"
#   }
#   activemq_opts_memory = "-Xms1g -Xmx3g"
# }

# Comment to disable the MongoDB metrics exporter
mongodb_metrics_exporter = {}

mongodb = {

  node_selector = {
    service = "state-database"
  }
  cluster = {
    replicas      = 1
    database_name = "database"
  }

  persistence = {
    shards = {
      storage_size        = "8Gi"
      storage_provisioner = "pd.csi.storage.gke.io"
      parameters = {
        type = "pd-ssd"
      }
    }
    configsvr = {
      storage_size        = "3Gi"
      storage_provisioner = "pd.csi.storage.gke.io"
      parameters = {
        type = "pd-ssd"
      }
    }
  }
}

# Nullify to disable sharding, each nullification of subobject will result in the use of default values 
# mongodb_sharding = {}

#memorystore = {
#  node_type      = "HIGHMEM_MEDIUM"
#  engine_version = "VALKEY_8_0"
#  replica_count  = 1
#  engine_configs = {
#    "maxmemory-policy" = "volatile-lru"
#  }
#}
gcs_os = {}

seq = {
  node_selector = { service = "monitoring" }
}

grafana = {
  node_selector = { service = "monitoring" }
}

node_exporter = {
  node_selector = {}
}

prometheus = {
  node_selector = { service = "metrics" }
}

metrics_exporter = {
  node_selector = { service = "metrics" }
}

#parition_metrics_exporter = {
#  node_selector = { service = "metrics" }
#  extra_conf    = {
#  env = {
#    MongoDB__AllowInsecureTls           = true
#    Serilog__MinimumLevel               = "Information"
#    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
#    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
#    MongoDB__DataRetention                 = "1.00:00:00" # 1 day retention
#}
#  }
#}

fluent_bit = {
  is_daemonset  = true
  node_selector = {}
}

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
  node_selector     = { service = "control-plane" }
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
  node_selector = { service = "monitoring" }
}

# Parameters of the compute plane
compute_plane = {
  # Default partition that uses the C# extension for the worker
  default = {
    node_selector = { service = "workers" }
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
        image = "dockerhubaneo/armonik-dynamic-dotnet-worker"
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
      min_replica_count = 0
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
  # Partition for the pymonik worker
  pymonik = {
    # number of replicas for each deployment of compute plane
    replicas = 0
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "50m"
        memory = "50Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/harmonic_snake"
        tag   = "python-3.10.12"
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
        requests = {
          cpu    = "50m"
          memory = "50Mi"
        }
      }
    ]
    hpa = {
      type              = "prometheus"
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 0
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
    node_selector = { service = "workers" }
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
      min_replica_count = 0
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
    node_selector = { service = "workers" }
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
      min_replica_count = 0
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
    node_selector = { service = "workers" }
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
      min_replica_count = 0
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

# load_balancer = {
#   extra_env = {
#     RUST_LOG="info,armonik=info,load_balancer=info"
#   }
# }

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  tls                  = false
  mtls                 = false
  generate_client_cert = false
  node_selector        = { service = "control-plane" }
}

configurations = {
  core = {
    env = {
      Amqp__AllowHostMismatch                    = true
      Amqp__MaxPriority                          = "10"
      Amqp__MaxRetries                           = "5"
      Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
      Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
      Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
      MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
      MongoDB__TableStorage__PollingDelay        = "00:00:01"
      MongoDB__AllowInsecureTls                  = true
      MongoDB__DataRetention                     = "1.00:00:00" # 1 day retention
      Redis__Timeout                             = 3000
      Redis__SslHost                             = ""
      Redis__TtlTimeSpan                         = "1.00:00:00" # 1 day retention
      Submitter__DeletePayload                   = true
    }
  }
  control = {
    env = {
      Submitter__MaxErrorAllowed = 50
    }
  }
  worker = {
    env = {
      target_zip_path = "/tmp"
    }
  }
  jobs = { env = { MongoDB__DataRetention = "1.00:00:00" } }
}

environment_description = {
  name        = "gcp-dev"
  version     = "0.0.0"
  description = "GCP environment"
  color       = "#80ff80"
}

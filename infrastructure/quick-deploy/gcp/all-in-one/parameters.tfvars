labels = {}

# Logging level
logging_level = "Information"

keda = {
  node_selector = { service = "monitoring" }
}

metrics_server = null

mongodb = {
  node_selector = { service = "state-database" }
}

memorystore = {
  memory_size_gb = 20
  auth_enabled   = true
  connect_mode   = "PRIVATE_SERVICE_ACCESS"
  redis_configs = {
    "maxmemory-gb"     = "18"
    "maxmemory-policy" = "volatile-lru"
  }
  reserved_ip_range       = "10.1.0.0/16"
  redis_version           = "REDIS_7_0"
  tier                    = "STANDARD_HA"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  replica_count           = 3
  read_replicas_mode      = "READ_REPLICAS_ENABLED"
}
#gcs_os = {}

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
  image_tag     = "0.17.0"
  extra_conf = {
    MongoDB__AllowInsecureTls              = true
    Serilog__MinimumLevel                  = "Information"
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
  }
}

#parition_metrics_exporter = {
#  node_selector = { service = "metrics" }
#  extra_conf    = {
#    MongoDB__AllowInsecureTls           = true
#    Serilog__MinimumLevel               = "Information"
#    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
#    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
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
  image             = "submitterpubsub"
  tag               = "0.17.0-pubsub"
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
    #node_selector = { service = "workers" }
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
      image = "pollingagentpubsub"
      tag   = "0.17.0-pubsub"
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
      image = "pollingagentpubsub"
      tag   = "0.17.0-pubsub"
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
      image = "pollingagentpubsub"
      tag   = "0.17.0-pubsub"
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
      image = "pollingagentpubsub"
      tag   = "0.17.0-pubsub"
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

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  tls                  = false
  mtls                 = false
  generate_client_cert = false
  node_selector        = { service = "control-plane" }
}

# Job to insert partitions in the database
job_partitions_in_database = {
  node_selector = { service = "control-plane" }
}

# Authentication behavior
authentication = {
  node_selector = { service = "control-plane" }
}

extra_conf = {
  core = {
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    MongoDB__TableStorage__PollingDelay    = "00:00:01"
    MongoDB__DataRetention                 = "10.00:00:00"
    MongoDB__AllowInsecureTls              = true
    Redis__Timeout                         = 3000
    Redis__SslHost                         = ""
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

environment_description = {
  name        = "gcp-dev"
  version     = "0.0.0"
  description = "GCP environment"
  color       = "#80ff80"
}

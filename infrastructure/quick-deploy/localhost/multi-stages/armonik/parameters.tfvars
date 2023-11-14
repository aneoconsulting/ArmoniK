# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Job to insert partitions in the database
job_partitions_in_database = {
}

# Parameters of control plane
control_plane = {
  limits = {
    cpu    = "1000m"  # set to null if you don't want to set it
    memory = "2048Mi" # set to null if you don't want to set it
  }
  requests = {
    cpu    = "200m"  # set to null if you don't want to set it
    memory = "500Mi" # set to null if you don't want to set it
  }
  hpa = {
    polling_interval  = 15
    cooldown_period   = 300
    min_replica_count = 2
    max_replica_count = 2
    behavior = {
      restore_to_original_replica_count = true
      stabilization_window_seconds      = 300
      type                              = "Percent"
      value                             = 100
      period_seconds                    = 15
    }
    triggers = [
      {
        type        = "cpu"
        metric_type = "Utilization"
        value       = "80"
      },
      {
        type        = "memory"
        metric_type = "Utilization"
        value       = "80"
      },
    ]
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
  node_selector = { service = "monitoring" }
}

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.9
admin_0_9_gui = {
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

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.8 (previously called old admin gui)
admin_0_8_gui = {
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
  app = {
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
  node_selector      = { service = "monitoring" }
}

# Parameters of the compute plane
compute_plane = {
  default = {
    # ArmoniK polling agent
    polling_agent = {
      limits = {
        cpu    = "2000m"  # set to null if you don't want to set it
        memory = "2048Mi" # set to null if you don't want to set it
      }
      requests = {
        cpu    = "200m"  # set to null if you don't want to set it
        memory = "256Mi" # set to null if you don't want to set it
      }
    }
    # ArmoniK workers
    worker = [
      {
        image = "dockerhubaneo/armonik_worker_dll"
        limits = {
          cpu    = "1000m"  # set to null if you don't want to set it
          memory = "1024Mi" # set to null if you don't want to set it
        }
        requests = {
          cpu    = "200m"  # set to null if you don't want to set it
          memory = "512Mi" # set to null if you don't want to set it
        }
      }
    ]
    hpa = {
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 1
      max_replica_count = 5
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
  limits               = null
  requests             = null
  generate_client_cert = false
}

authentication = {
}

extra_conf = {
  core = {
    Amqp__AllowHostMismatch                    = true
    Amqp__MaxPriority                          = "10"
    Amqp__MaxRetries                           = "5"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
    MongoDB__AllowInsecureTls                  = true
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
    MongoDB__DataRetention                     = "1.00:00:00"
    Redis__Timeout                             = 30000
    Redis__SslHost                             = "127.0.0.1"
    Redis__TtlTimeSpan                         = "1.00:00:00"
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

# Extra configuration for jobs connecting to database
jobs_in_database_extra_conf = { MongoDB__DataRetention = "1.00:00:00" }

environment_description = {
  name        = "local-dev"
  version     = "0.0.0"
  description = "Local development environment"
  color       = "blue"
}

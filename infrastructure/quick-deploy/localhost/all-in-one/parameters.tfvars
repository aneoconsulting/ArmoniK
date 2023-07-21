# Logging level
logging_level = "Information"

# Uncomment to deploy metrics server
#metrics_server = {}

# Object storage
# Uncomment either the `redis` or the `minio` parameter
#redis = {}
#minio = {}

# Uncomment this to have minio S3 enabled instead of hostpath shared_storage
#minio_s3_fs = {} # Shared storage

metrics_exporter = {
  extra_conf = {
    MongoDB__AllowInsecureTls              = true
    Serilog__MinimumLevel                  = "Information"
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
  }
}

/*parition_metrics_exporter = {
  extra_conf = {
    MongoDB__AllowInsecureTls           = true
    Serilog__MinimumLevel               = "Information"
    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
  }
}*/

# Parameters of control plane
control_plane = {
  limits = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests = {
    cpu    = "50m"
    memory = "50Mi"
  }
  default_partition = "default"
}

# Parameters of admin GUI
# Parameters of admin GUI
admin_gui = {
  limits = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests = {
    cpu    = "50m"
    memory = "50Mi"
  }
}

# Old GUI
admin_old_gui = {
  api = {
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "50Mi"
    }
  }
  old = {
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "50Mi"
    }
  }
}

# Parameters of the compute plane
compute_plane = {
  # Default partition that uses the C# extension for the worker
  default = {
    # number of replicas for each deployment of compute plane
    replicas      = 0
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
        image  = "dockerhubaneo/armonik_worker_dll"
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
      max_replica_count = 5
      behavior          = {
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
    replicas      = 0
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
        image  = "dockerhubaneo/armonik_core_stream_test_worker"
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
      max_replica_count = 5
      behavior          = {
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
    replicas      = 0
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
        image  = "dockerhubaneo/armonik_core_htcmock_test_worker"
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
      max_replica_count = 5
      behavior          = {
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
    replicas      = 0
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
        image  = "dockerhubaneo/armonik_core_bench_test_worker"
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
      max_replica_count = 5
      behavior          = {
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
    MongoDB__DataRetention                     = "10.00:00:00"
    Redis__Timeout                             = 30000
    Redis__SslHost                             = "127.0.0.1"
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

activemq = {
  image_name = "dockerhubaneo/activemq"
  image_tag  = "5.18.2"
}

mongodb = {
  image_name = "dockerhubaneo/mongodb"
  image_tag  = "6.0.7"
}

node_exporter = {
  image_name = "dockerhubaneo/nodeexporter"
  image_tag  = "1.6.0"
}

prometheus = {
  image_name = "dockerhubaneo/prometheus"
  image_tag  = "2.45.0"
}

grafana = {
  image_name = "dockerhubaneo/grafana"
  image_tag  = "10.0.2"
}

redis = {
  image_name = "dockerhubaneo/redis"
  image_tag  = "7.0.12"
}

seq = {
  image_name     = "dockerhubaneo/seq"
  image_tag      = "2023.3"
  cli_image_name = "dockerhubaneo/seqcli"
  cli_image_tag  = "2023.2"
}
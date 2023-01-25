# Uncomment to deploy metrics server
#metrics_server = {}

# Parameters for ActiveMQ
activemq = {
  image_name = "symptoma/activemq"
  image_tag  = "5.16.4"
}

# Parameters for MongoDB
mongodb = {
  image_name = "mongo"
  image_tag  = "5.0.9"
}

# Parameters for Redis
redis = {
  image_name = "redis"
  image_tag  = "6.2.7"
}

seq = {
  image_name = "datalust/seq"
  image_tag  = "2022.1"
}

grafana = {
  image_name = "grafana/grafana"
  image_tag  = "9.2.1"
}

node_exporter = {
  image_name = "prom/node-exporter"
  image_tag  = "v1.3.1"
}

prometheus = {
  image_name = "prom/prometheus"
  image_tag  = "v2.36.1"
}

metrics_exporter = {
  image_name = "dockerhubaneo/armonik_control_metrics"
  image_tag  = "0.8.3"
}

//parition_metrics_exporter = {
//  image_name = "dockerhubaneo/armonik_control_partition_metrics"
//  image_tag = "0.8.3"
//}

fluent_bit = {
  image_name   = "fluent/fluent-bit"
  image_tag    = "1.9.9"
  is_daemonset = true
}


# Logging level
logging_level = "Information"


# Job to insert partitions in the database
job_partitions_in_database = {
  image = "rtsp/mongosh"
  tag   = "1.5.4"
}

# Parameters of control plane
control_plane = {
  image = "dockerhubaneo/armonik_control"
  tag   = "0.8.3"
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
    image = "dockerhubaneo/armonik_admin_api"
    tag   = "0.7.2"
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
    image = "dockerhubaneo/armonik_admin_app"
    tag   = "0.7.2"
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
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.8.3"
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
        tag   = "0.8.2"
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
  image                = "nginxinc/nginx-unprivileged"
  tag                  = "1.23.2"
  tls                  = false
  mtls                 = false
  generate_client_cert = false
}

authentication = {
  image = "rtsp/mongosh"
  tag   = "1.5.4"
}

extra_conf = {
  core = {
    MongoDB__TableStorage__PollingDelayMin = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax = "00:00:10"
  }
}

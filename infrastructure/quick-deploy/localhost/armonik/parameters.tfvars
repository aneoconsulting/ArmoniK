# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Polling delay to MongoDB
# according to the size of the task and/or the application
mongodb_polling_delay = {
  min_polling_delay = "00:00:01"
  max_polling_delay = "00:00:10"
}

# Pod to insert partitions in the database
pod_partitions_in_database = {
  name               = "pod-partitions-in-database"
  image              = "rtsp/mongosh"
  tag                = "1.5.4"
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
}

# Parameters of control plane
control_plane = {
  name               = "control-plane"
  service_type       = "ClusterIP"
  replicas           = 1
  image              = "dockerhubaneo/armonik_control"
  tag                = "0.6.1"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m" # set to null if you don't want to set it
    memory = "2048Mi" # set to null if you don't want to set it
  }
  requests           = {
    cpu    = "200m" # set to null if you don't want to set it
    memory = "500Mi" # set to null if you don't want to set it
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
  hpa                = {
    polling_interval  = 15
    cooldown_period   = 300
    min_replica_count = 2
    max_replica_count = 2
    behavior          = {
      restore_to_original_replica_count = true
      stabilization_window_seconds      = 300
      type                              = "Percent"
      value                             = 100
      period_seconds                    = 15
    }
    triggers          = [
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
  default_partition  = "default"
}

# Parameters of admin GUI
admin_gui = {
  api                = {
    name     = "admin-api"
    replicas = 1
    image    = "dockerhubaneo/armonik_admin_api"
    tag      = "0.6.0"
    port     = 3333
    limits   = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  app                = {
    name     = "admin-app"
    replicas = 1
    image    = "dockerhubaneo/armonik_admin_app"
    tag      = "0.6.0"
    port     = 1080
    limits   = {
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
  default = {
    partition_data                   = {
      priority              = 1
      reserved_pods         = 50
      max_pods              = 100
      preemption_percentage = 20
      parent_partition_ids  = []
      pod_configuration     = null
    }
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    image_pull_secrets               = ""
    node_selector                    = {}
    annotations                      = {}
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.6.1"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "2000m" # set to null if you don't want to set it
        memory = "2048Mi" # set to null if you don't want to set it
      }
      requests          = {
        cpu    = "200m" # set to null if you don't want to set it
        memory = "256Mi" # set to null if you don't want to set it
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.7.0-SNAPSHOT.45.433f857"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "1000m" # set to null if you don't want to set it
          memory = "1024Mi" # set to null if you don't want to set it
        }
        requests          = {
          cpu    = "200m" # set to null if you don't want to set it
          memory = "512Mi" # set to null if you don't want to set it
        }
      }
    ]
    hpa                              = {
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 1
      max_replica_count = 5
      behavior          = {
        restore_to_original_replica_count = true
        stabilization_window_seconds      = 300
        type                              = "Percent"
        value                             = 100
        period_seconds                    = 15
      }
      triggers          = [
        {
          type = "prometheus"
        },
      ]
    }
  },
}

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  name               = "ingress"
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "nginxinc/nginx-unprivileged"
  tag                = "1.23.0"
  image_pull_policy  = "IfNotPresent"
  http_port          = 5000
  grpc_port          = 5001
  limits             = {
    cpu    = "200m"
    memory = "100Mi"
  }
  requests           = {
    cpu    = "1m"
    memory = "1Mi"
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
  tls                = false
  mtls               = false
}

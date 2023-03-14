# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Job to insert partitions in the database
job_partitions_in_database = {
  name               = "job-partitions-in-database"
  image              = "rtsp/mongosh"
  tag                = "1.7.1"
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
}

# Parameters of control plane
control_plane = {
  name              = "control-plane"
  service_type      = "ClusterIP"
  replicas          = 1
  image             = "dockerhubaneo/armonik_control"
  tag               = "0.11.1"
  image_pull_policy = "IfNotPresent"
  port              = 5001
  limits = {
    cpu    = "1000m"  # set to null if you don't want to set it
    memory = "2048Mi" # set to null if you don't want to set it
  }
  requests = {
    cpu    = "200m"  # set to null if you don't want to set it
    memory = "500Mi" # set to null if you don't want to set it
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
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
  name  = "admin-app"
  image = "dockerhubaneo/armonik_admin_app"
  tag   = "main"
  port  = 1080
  limits = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  service_type       = "ClusterIP"
  replicas           = 1
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = {}
}

# Parameters of old admin GUI
admin_old_gui = {
  api = {
    name  = "admin-api"
    image = "dockerhubaneo/armonik_admin_api"
    tag   = "0.7.2"
    port  = 3333
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
    name  = "admin-old-gui"
    image = "dockerhubaneo/armonik_admin_app"
    tag   = "0.8.0"
    port  = 1080
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
  default = {
    partition_data = {
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
    polling_agent = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.11.1"
      image_pull_policy = "IfNotPresent"
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
        name              = "worker"
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.9.1"
        image_pull_policy = "IfNotPresent"
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
  name                  = "ingress"
  service_type          = "LoadBalancer"
  replicas              = 1
  image                 = "nginxinc/nginx-unprivileged"
  tag                   = "1.23.3"
  image_pull_policy     = "IfNotPresent"
  http_port             = 5000
  grpc_port             = 5001
  limits                = null
  requests              = null
  image_pull_secrets    = ""
  node_selector         = {}
  annotations           = {}
  tls                   = false
  mtls                  = false
  generate_client_cert  = false
  custom_client_ca_file = ""
}

authentication = {
  name                    = "job-authentication-in-database"
  image                   = "rtsp/mongosh"
  tag                     = "1.7.1"
  image_pull_policy       = "IfNotPresent"
  image_pull_secrets      = ""
  node_selector           = {}
  authentication_datafile = ""
  require_authentication  = false
  require_authorization   = false
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

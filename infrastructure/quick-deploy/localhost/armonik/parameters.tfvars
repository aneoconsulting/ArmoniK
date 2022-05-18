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

# Parameters of control plane
control_plane = {
  name               = "control-plane"
  service_type       = "ClusterIP"
  replicas           = 1
  image              = "dockerhubaneo/armonik_control"
  tag                = "0.5.9"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests           = {
    cpu    = "200m"
    memory = "256Mi"
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
}

# Parameters of the compute plane
compute_plane = [
  {
    name                             = "compute-plane"
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    image_pull_secrets               = ""
    node_selector                    = {}
    annotations                      = {}
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.5.9"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "1000m"
        memory = "2048Mi"
      }
      requests          = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.5.7"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
        requests          = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    ]
    hpa                              = {
      type              = "prometheus"
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
      triggers          = {
        metric_name = "armonik_tasks_queued"
        threshold   = "2"
      }
    }
  }
]

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  name               = "ingress"
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "nginx"
  tag                = "latest"
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
  tls                = true
  mtls               = true
}

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
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "dockerhubaneo/armonik_control"
  tag                = "0.5.6"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m"
    memory = "1024Mi" 
  }
  requests           = {
    cpu    = "100m" 
    memory = "50Mi" 
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
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.5.6"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "1000m"
        memory = "1024Mi"
      }
      requests          = {
        cpu    = "100m" 
        memory = "50Mi" 
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        port              = 80
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.5.3"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "200m" 
          memory = "512Mi" 
        }
        requests          = {
          cpu    = "100m" 
          memory = "50Mi" 
        }
      }
    ]
    hpa                              = {
      min_replicas   = 1
      max_replicas   = 5
      object_metrics = [
        {
          described_object = {
            api_version = "batch/v1"
            kind        = "Job"
          }
          metric_name      = "armonik_tasks_queued"
          target           = {
            type                = "AverageValue" # "Value", "Utilization" or "AverageValue"
            average_value       = 2
            average_utilization = 0
            value               = 0
          }
        }
      ]
    }
  }
]

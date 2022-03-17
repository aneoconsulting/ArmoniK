# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Parameters of control plane
control_plane = {
  name               = "control-plane"
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "dockerhubaneo/armonik_control"
  tag                = "0.5.1"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests           = {
    cpu    = "100m"
    memory = "128Mi"
  }
  image_pull_secrets = ""
  node_selector      = {}
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
      tag               = "0.5.1"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "100m"
        memory = "128Mi"
      }
      requests          = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        port              = 80
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.5.1"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "920m"
          memory = "2048Mi"
        }
        requests          = {
          cpu    = "50m"
          memory = "100Mi"
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

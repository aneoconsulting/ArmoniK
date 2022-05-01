# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubeconfig path
k8s_config_path = "~/.kube/config"

# Kubeconfig context
k8s_config_context = "default"

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
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-control-plane"
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
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
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
        image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
        tag               = "0.5.3"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "100m"
          memory = "512Mi"
        }
        requests          = {
          cpu    = "50m"
          memory = "50Mi"
        }
      }
    ]
    /*hpa                              = {
      min_replicas   = 1
      max_replicas   = 100
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
    }*/
    # Enable only one KEDA HPA
    keda_hpa_activemq                = {
      enabled            = true
      polling_interval   = 30
      cooldown_period    = 300
      idle_replica_count = 0
      min_replica_count  = 1
      max_replica_count  = 100
      behavior           = {
        restore_to_original_replica_count = true
        stabilization_window_seconds      = 300
        type                              = "Percent"
        value                             = 100
        period_seconds                    = 15
      }
      triggers           = {
        destination_name  = "q0"
        target_queue_size = "50"
      }
    }
  }
]

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
  tag                = "0.5.7"
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
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
      tag               = "0.5.7"
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
        image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
        tag               = "0.5.3"
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
    # Enable only one KEDA HPA
    /*hpa                = {
      type            = "activemq"
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
        target_queue_size = "10"
      }
    }
    hpa                              = {
      type               = "cloudwatch"
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
        queue_name             = "q0"
        target_metric_value    = "10"
        metric_stat_period     = "60"
        metric_collection_time = "60"
        min_metric_value       = "0"
        metric_end_time_offset = "0"
        namespace              = "AWS/AmazonMQ"
        metric_name            = "QueueSize"
      }
    }*/
    hpa                              = {
      type               = "prometheus"
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
        metric_name = "armonik_tasks_queued"
        threshold   = "2"
      }
    }
  }
]

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
  tag                = "0.5.7"
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
      tag               = "0.5.7"
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

# Kubernetes namespace
namespace = "armonik"

# Node selector
node_selector = {}

# Logging level
logging_level = "Information"

# Parameters of control plane
control_plane = {
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "dockerhubaneo/armonik_control"
  tag                = "0.4.1-trypemfiles.5.cc68029"
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
}

# Parameters of the compute plane
compute_plane = {
  # number of replicas for each deployment of compute plane
  replicas                         = 1
  termination_grace_period_seconds = 30
  # number of queues according to priority of tasks
  max_priority                     = 1
  image_pull_secrets               = ""
  # ArmoniK polling agent
  polling_agent                    = {
    image             = "dockerhubaneo/armonik_pollingagent"
    tag               = "0.4.1-trypemfiles.5.cc68029"
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
      tag               = "0.4.0"
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
}

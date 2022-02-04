# Namespace of ArmoniK storage
namespace = "armonik"

# Logging level
logging_level = "Information"

# Fluent-bit
fluent_bit = {
  image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit"
  tag   = "1.3.11"
}

# Parameters of control plane
control_plane = {
  replicas           = 1
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-control-plane"
  tag                = "0.4.0"
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
    image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
    tag               = "0.4.0"
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
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
      # HTC Mock
      #image             = "dockerhubaneo/armonik_worker_htcmock"
      tag               = "0.2.1"
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

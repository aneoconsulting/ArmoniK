# Namespace of ArmoniK storage
namespace = "armonik"

# Logging level
logging_level = "Information"

# Fluent-bit
fluent_bit = {
  name = "fluent-bit"
  image = "fluent/fluent-bit"
  tag   = "1.3.11"
  name  = "fluent-bit"
}

# Secrets
secrets = {
  redis_username_secret = "redis-user"
  redis_username_key    = "username"
  redis_password_secret = "redis-user"
  redis_password_key    = "password"
  redis_certificate_secret = "redis-client-certificates"
  redis_certificate_file = "chain.pem"

  mongodb_username_secret = "mongodb-user"
  mongodb_username_key    = "username"
  mongodb_password_secret = "mongodb-user"
  mongodb_password_key    = "password"
  mongodb_certificate_secret = "mongodb-client-certificates"
  mongodb_certificate_file = "chain.pem"

  activemq_username_secret = "activemq-user"
  activemq_username_key    = "username"
  activemq_password_secret = "activemq-user"
  activemq_password_key    = "password"
  activemq_certificate_secret = "activemq-client-certificates"
  activemq_certificate_file = "chain.pem"
}

# Parameters of control plane
control_plane = {
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

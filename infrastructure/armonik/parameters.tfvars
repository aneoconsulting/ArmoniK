# Namespace of ArmoniK storage
namespace = "armonik"

# Logging level
logging_level = "Information"

# Needed storage for each ArmoniK data type
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  shared         = "HostPath"
  # Mandatory: If you want execute the HTC Mock sample, you must set this parameter to "Redis", otherwise let it to ""
  external       = "Redis"
}

# Endpoints and secrets of storage resources
storage_endpoint_url = {
  mongodb        = {
    url    = "mongodb://192.168.1.13:27017"
    secret = ""
  }
  redis          = {
    url    = "192.168.1.13:6379"
    secret = "redis-storage-secret"
  }
  activemq       = {
    host   = "192.168.1.13"
    port   = "5672"
    secret = "activemq-storage-secret"
  }
  shared_storage = {
    host   = ""
    secret = ""
    # Path to external shared storage from which worker containers upload .dll
    path   = "/data"
  }
}

# Parameters of control plane
control_plane = {
  replicas          = 1
  image             = "dockerhubaneo/armonik_control"
  tag               = "0.0.6"
  image_pull_policy = "IfNotPresent"
  port              = 5001
}

# Parameters of the compute plane
compute_plane = {
  # number of replicas for each deployment of compute plane
  replicas      = 1
  # number of queues according to priority of tasks
  max_priority  = 1
  # ArmoniK polling agent
  polling_agent = {
    image             = "dockerhubaneo/armonik_pollingagent"
    tag               = "0.0.6"
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
  worker        = [
    {
      name              = "worker"
      port              = 80
      image             = "dockerhubaneo/armonik_worker_dll"
      # HTC Mock
      #image             = "dockerhubaneo/armonik_worker_htcmock"
      tag               = "0.0.6"
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
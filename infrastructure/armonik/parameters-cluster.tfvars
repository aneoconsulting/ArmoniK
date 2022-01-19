# Namespace of ArmoniK storage
namespace = "armonik"

# Logging level
logging_level = "Information"

# Use monitoring
monitoring = {
  namespace = "armonik-monitoring"
  seq       = true
  grafana   = true
  prometheus = true
  dashboard = false
}

# Needed storage for each ArmoniK data type
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  shared         = "NFS"
  # Mandatory: If you want execute the HTC Mock sample, you must set this parameter to "Redis", otherwise let it to ""
  external       = "Redis"
}

# Endpoints and secrets of storage resources
storage_endpoint_url = {
  mongodb  = {
    url    = "mongodb://172.31.33.26:31444"
    secret = ""
  }
  redis    = {
    url    = ""
    secret = "redis-storage-secret"
  }
  activemq = {
    host   = "172.31.33.110"
    port   = "32327"
    secret = "activemq-storage-secret"
  }
  shared   = {
    host   = "172.31.23.199"
    secret = ""
    # Path to external shared storage from which worker containers upload .dll
    path   = "/data"
  }
  external = {
    url    = "172.31.42.54:32285"
    secret = "external-redis-storage-secret"
  }
}

# Parameters of control plane
control_plane = {
  replicas          = 1
  image             = "dockerhubaneo/armonik_control"
  tag               = "0.2.0-redis.29.20d9f60"
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
    tag               = "0.2.0-redis.29.20d9f60"
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
      tag               = "0.1.1"
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
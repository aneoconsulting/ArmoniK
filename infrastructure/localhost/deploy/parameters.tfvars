# Global parameters
namespace          = "armonik"
k8s_config_context = "default"
k8s_config_path    = "~/.kube/config"
# number of queues according to the priority of tasks
max_priority       = 1

# MongoDB
mongodb = {
  replicas = 1
  port     = 27017
}

# Redis
redis = {
  replicas = 1
  port     = 6379
  secret   = "redis-storage-secret"
}

# Parameters for ActiveMQ
activemq = {
  replicas = 1
  port     = [
    { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
    { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
    { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
    { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
    { name = "ws", port = 61614, target_port = 61614, protocol = "TCP" },
    { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
  ]
  secrets  = {
    activemq = "activemq-storage-secret"
    armonik  = "activemq-storage-secret-for-armonik"
  }
}

# Local shared persistent volume
local_shared_storage = {
  storage_class           = {
    name = "nfs"
  }
  persistent_volume       = {
    name      = "nfs-pv"
    size      = "5Gi"
    # Path of a directory in you local machine
    host_path = "/data"
  }
  persistent_volume_claim = {
    name = "nfs-pvc"
    size = "2Gi"
  }
}

# Parameters for Seq
# Seq is the intelligent search, analysis, and alerting server built specifically for modern structured log data.
seq = {
  replicas = 1
  port     = [
    { name = "ingestion", port = 5341, target_port = 5341, protocol = "TCP" },
    { name = "web", port = 8080, target_port = 80, protocol = "TCP" }
  ]
}

# ArmoniK components
armonik = {
  # Logging level
  logging_level    = "Information"
  # ArmoniK contol plane
  control_plane    = {
    replicas          = 1
    image             = "dockerhubaneo/armonik_control"
    tag               = "0.0.4"
    image_pull_policy = "IfNotPresent"
    port              = 5001
  }
  # ArmoniK compute plane
  compute_plane    = {
    # number of replicas for each deployment of compute plane
    replicas      = 1
    # ArmoniK polling agent
    polling_agent = {
      image             = "dockerhubaneo/armonik_pollingagent"
      tag               = "0.0.4"
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
    # ArmoniK computes
    compute       = [
      {
        name              = "compute"
        port              = 80
        image             = "dockerhubaneo/armonik_worker_dll"
        tag               = "0.0.4"
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
  # Storage used by ArmoniK
  storage_services = {
    object_storage_type         = "MongoDB"
    table_storage_type          = "MongoDB"
    queue_storage_type          = "Amqp"
    lease_provider_storage_type = "MongoDB"
    # Mandatory: If you want execute the HtcMock sample, you must set this parameter to ["Redis"], otherwise let it to []
    external_storage_types      = []
    # Path of a directory in a pod, which contains data shared between pods and your local machine
    shared_storage_target_path  = "/data"
  }
}

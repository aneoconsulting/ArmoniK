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

# Parameters for ActiveMQ
activemq = {
  replicas = 1
  port     = 5672
  secret   = "activemq-storage-secret"
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

# ArmoniK components
armonik = {
  # ArmoniK contol plane
  control_plane    = {
    replicas          = 1
    image             = "dockerhubaneo/armonik_control"
    tag               = "dev-6330"
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
      tag               = "dev-6330"
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
        image             = "dockerhubaneo/armonik_compute"
        tag               = "dev-6330"
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
    queue_storage_type          = "MongoDB"
    lease_provider_storage_type = "MongoDB"
    # Path of a directory in a pod, which contains data shared between pods and your local machine
    shared_storage_target_path  = "/data"
  }
}

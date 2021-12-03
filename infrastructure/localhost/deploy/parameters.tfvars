# Global parameters
namespace          = "armonik"
k8s_config_context = "default"
k8s_config_path    = "~/.kube/config"
# number of queues according to the priority of tasks
priority           = 1

# Redis
/*redis = {
  replicas = 1
  port     = 6379
  secret   = "redis-storage-secret"
}*/

# ActiveMQ
/*activemq = {
  replicas = 1
  port     = [
    { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
    { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
    { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
    { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
    { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
  ]
  secret   = "activemq-storage-secret"
}*/

# MongoDB
mongodb = {
  replicas = 1
  port     = 27017
}

# Local shared persistent volume
local_shared_storage = {
  storage_class           = {
    provisioner            = "kubernetes.io/no-provisioner"
    name                   = "nfs"
    volume_binding_mode    = "WaitForFirstConsumer"
    allow_volume_expansion = true
  }
  persistent_volume       = {
    name                             = "nfs-pv"
    persistent_volume_reclaim_policy = "Delete"
    access_modes                     = ["ReadWriteMany"]
    size                             = "5Gi"
    # Path of a directory in you local machine
    host_path                        = "/data"
  }
  persistent_volume_claim = {
    name         = "nfs-pvc"
    access_modes = ["ReadWriteMany"]
    size         = "2Gi"
  }
}

# ArmoniK components
armonik = {
  # ArmoniK contol plane
  control_plane    = {
    replicas          = 1
    image             = "dockerhubaneo/armonik_control"
    tag               = "dev-6284"
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
      tag               = "dev-6284"
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
        tag               = "dev-6284"
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
    object_storage         = {
      type = "MongoDB"
      url  = ""
      port = 0
    }
    table_storage          = {
      type = "MongoDB"
      url  = ""
      port = 0
    }
    queue_storage          = {
      type = "MongoDB"
      url  = ""
      port = 0
    }
    lease_provider_storage = {
      type = "MongoDB"
      url  = ""
      port = 0
    }
    shared_storage         = {
      claim_name  = "nfs-pvc"
      # Path of a directory in a pod, which contains data shared between pods and your local machine
      target_path = "/app/data"
    }
  }
}

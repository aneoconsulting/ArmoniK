# Global parameters
namespace = {
  description = "Namespace of ArmoniK resources"
  type        = string
}

k8s_config_path = {
  description = "Path pf the configuration file of K8s"
  type        = string
}

k8s_config_context = {
  description = "Context of K8s"
  type        = string
}

# number of queues according to priority of tasks
priority = {
  description = "Number of queues according to the priority of tasks"
  type        = number
}

# Redis
redis = {
  replicas = 1
  port     = 6379
  secret   = "redis-storage-secret"
}

# ActiveMQ
activemq = {
  replicas = 1
  port     = [
    { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
    { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
    { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
    { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
    { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
  ]
  secret   = "activemq-storage-secret"
}

# MongoDB
mongodb = {
  replicas = 1
  port     = 27017
}

# Local shared storage
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
    size                             = "10Gi"
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
  description = "Components of ArmoniK"
  type        = {
    # AmoniK control plane
    control_plane    = {
      replicas          = number
      image             = string
      tag               = string
      image_pull_policy = string
      port              = number
    }
    # AmoniK compute plane
    compute_plane    = {
      replicas      = number
      # AmoniK polling agent
      polling_agent = {
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = {
          cpu    = string
          memory = string
        }
        requests          = {
          cpu    = string
          memory = string
        }
      }
      # AmoniK compute
      compute       = [
        {
          name              = string
          port              = number
          image             = string
          tag               = string
          image_pull_policy = string
          limits            = {
            cpu    = string
            memory = string
          }
          requests          = {
            cpu    = string
            memory = string
          }
        }
      ]
    }
    # List of storage services used by ArmoniK
    storage_services = {
      object_storage         = {
        type = string
        url  = string
        port = number
      }
      table_storage          = {
        type = string
        url  = string
        port = number
      }
      queue_storage          = {
        type = string
        url  = string
        port = number
      }
      lease_provider_storage = {
        type = string
        url  = string
        port = number
      }
      shared_storage         = {
        claim_name  = string
        target_path = string
      }
    }
  }
}
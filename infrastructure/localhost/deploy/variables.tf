# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "armonik"
}

variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# number of queues according to priority of tasks
variable "max_priority" {
  description = "Number of queues according to the priority of tasks"
  type        = number
  default     = 1
}

# MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    replicas = number
    port     = number
  })
  default     = {
    replicas = 1
    port     = 27017
  }
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis of ArmoniK"
  type        = object({
    replicas = number,
    port     = number,
    secret   = string
  })
  default     = {
    replicas = 1
    port     = 6379
    secret   = "redis-storage-secret"
  }
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type        = object({
    replicas = number
    port     = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }))
    secret   = string
  })
  default     = {
    replicas = 1
    port     = [
      { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
      { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
      { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
      { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
      { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
    ]
    secret   = "activemq-storage-secret"
  }
}

# Local shared storage
variable "local_shared_storage" {
  description = "A local persistent volume used as NFS"
  type        = object({
    storage_class           = object({
      name = string
    })
    persistent_volume       = object({
      name      = string
      size      = string
      host_path = string
    })
    persistent_volume_claim = object({
      name = string
      size = string
    })
  })
  default     = {
    storage_class           = {
      name = "nfs"
    }
    persistent_volume       = {
      name      = "nfs-pv"
      size      = "10Gi"
      host_path = "/data"
    }
    persistent_volume_claim = {
      name = "nfs-pvc"
      size = "2Gi"
    }
  }
}

# Parameters for Seq
# Seq is the intelligent search, analysis, and alerting server built specifically for modern structured log data.
variable "seq" {
  description = "Parameters of Seq"
  type        = object({
    replicas = number
    port     = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }))
  })
  default     = {
    replicas = 1
    port     = [
      { name = "ingestion", port = 5341, target_port = 5341, protocol = "TCP" },
      { name = "web", port = 8080, target_port = 80, protocol = "TCP" }
    ]
  }
}

# ArmoniK components
variable "armonik" {
  description = "Components of ArmoniK"
  type        = object({
    # Logging level
    logging_level    = string
    # ArmoniK contol plane
    control_plane    = object({
      replicas          = number
      image             = string
      tag               = string
      image_pull_policy = string
      port              = number
    })
    # ArmoniK compute plane
    compute_plane    = object({
      # number of replicas for each deployment of compute plane
      replicas      = number
      # ArmoniK polling agent
      polling_agent = object({
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = object({
          cpu    = string
          memory = string
        })
        requests          = object({
          cpu    = string
          memory = string
        })
      })
      # ArmoniK computes
      compute       = list(object({
        name              = string
        port              = number
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = object({
          cpu    = string
          memory = string
        })
        requests          = object({
          cpu    = string
          memory = string
        })
      }))
    })
    # Storage used by ArmoniK
    storage_services = object({
      object_storage_type         = string
      table_storage_type          = string
      queue_storage_type          = string
      lease_provider_storage_type = string
      # Mandatory: If you want execute the HtcMock sample, you must set this parameter to ["Redis"], otherwise let it to []
      external_storage_types      = list(string)
      shared_storage_target_path  = string
    })
  })
  default     = {
    logging_level    = "Information"
    control_plane    = {
      replicas          = 1
      image             = "dockerhubaneo/armonik_control"
      tag               = "dev-6276"
      image_pull_policy = "IfNotPresent"
      port              = 5001
    }
    compute_plane    = {
      replicas      = 1
      polling_agent = {
        image             = "dockerhubaneo/armonik_pollingagent"
        tag               = "dev-6276"
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
      compute       = [
        {
          name              = "compute"
          port              = 80
          image             = "dockerhubaneo/armonik_compute"
          tag               = "dev-6276"
          image_pull_policy = "IfNotPresent"
          limits            = {
            cpu    = "920m"
            memory = "3966Mi"
          }
          requests          = {
            cpu    = "50m"
            memory = "3966Mi"
          }
        }
      ]
    }
    storage_services = {
      object_storage_type         = "MongoDB"
      table_storage_type          = "MongoDB"
      queue_storage_type          = "MongoDB"
      lease_provider_storage_type = "MongoDB"
      # Mandatory: If you want execute the HtcMock sample, you must set this parameter to ["Redis"], otherwise let it to []
      external_storage_types      = []
      shared_storage_target_path  = "/data"
    }
  }
}
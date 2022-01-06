# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik-storage"
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
  description = "Parameters of Redis"
  type        = object({
    replicas = number
    port     = number
  })
  default     = {
    replicas = 1
    port     = 6379
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

# Storage to be created
variable "storage" {
  description = "List of storage for each ArmoniK data to be created."
  type        = object({
    object         = string
    table          = string
    queue          = string
    lease_provider = string
    shared         = string
    external       = string
  })
  default     = {
    object         = "MongoDB"
    table          = "MongoDB"
    queue          = "MongoDB"
    lease_provider = "MongoDB"
    shared         = ""
    external       = ""
  }
}

# Kubernetes secrets for storage
variable "storage_kubernetes_secrets" {
  description = "List of Kubernetes secrets for the storage to be created"
  type        = object({
    mongodb  = string
    redis    = string
    activemq = string
  })
  default     = {
    mongodb  = ""
    redis    = "redis-storage-secret"
    activemq = "activemq-storage-secret"
  }
}
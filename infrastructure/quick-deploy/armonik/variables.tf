# Global variables
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
    replicas      = number
    port          = number
    image         = string
    tag           = string
    secret        = string
    node_selector = any
  })
  default     = {
    replicas      = 1
    port          = 27017
    image         = "mongo"
    tag           = "4.4.11"
    secret        = "mongodb-storage-secret"
    node_selector = {}
  }
}

# Logging level
variable "logging_level" {
  description = "Logging level"
  type        = string
  default     = "Information"
}

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type        = object({
    name  = string
    image = string
    tag   = string
  })
  default     = {
    name  = "fluent-bit"
    image = "fluent/fluent-bit"
    tag   = "1.3.11"
  }
}

# Kubernetes namespaces
variable "kubernetes_namespaces" {
  description = "Kubernetes namespaces"
  type        = any
  default     = {
    storage    = "armonik-storage"
    monitoring = "armonik-monitoring"
    armonik    = "armonik"
  }
}

# Kubernetes secrets
variable "kubernetes_secrets" {
  description = "Kubernetes secrets"
  type        = any
  default     = {
    activemq_server = "activemq-storage-secret"
    activemq_client = "activemq-storage-secret"
    mongodb_server  = "mongodb-storage-secret"
    mongodb_client  = "mongodb-storage-secret"
    redis_server    = "redis-storage-secret"
    redis_client    = "redis-storage-secret"
    external_client = "external-storage-secret"
  }
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type        = object({
    replicas           = number
    image              = string
    tag                = string
    image_pull_policy  = string
    port               = number
    limits             = object({
      cpu    = string
      memory = string
    })
    requests           = object({
      cpu    = string
      memory = string
    })
    image_pull_secrets = string
  })
  default     = {
    replicas           = 1
    image              = "dockerhubaneo/armonik_control"
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
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type        = object({
    replicas                         = number
    termination_grace_period_seconds = number
    # number of queues according to priority of tasks
    max_priority                     = number
    image_pull_secrets               = string
    polling_agent                    = object({
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
    worker                           = list(object({
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
  default     = {
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    # number of queues according to priority of tasks
    max_priority                     = 1
    image_pull_secrets               = ""
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "dockerhubaneo/armonik_pollingagent"
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
        image             = "dockerhubaneo/armonik_worker_dll"
        # HTC Mock
        #image             = "dockerhubaneo/armonik_worker_htcmock"
        tag               = "0.1.2-SNAPSHOT.4.cfda5d1"
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
}

# Storage endpoint URLS
variable "storage_endpoint_url" {
  description = "Storage endpoint URLS"
  type        = any
  default     = {}
}

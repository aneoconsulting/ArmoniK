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

# Logging level
variable "logging_level" {
  description = "Logging level"
  type        = string
  default     = "Information"
}

# Parameters for Seq
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

# Needed storage for each ArmoniK data type
variable "storage" {
  description = "Needed storage for each ArmoniK data type"
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
    queue          = "Amqp"
    lease_provider = "MongoDB"
    shared         = "HostPath"
    external       = ""
  }
}

# Endpoints and secrets of storage resources
variable "storage_endpoint_url" {
  description = "Endpoints and secrets of storage resources"
  type        = object({
    mongodb  = object({
      url    = string
      secret = string
    })
    redis    = object({
      url    = string
      secret = string
    })
    activemq = object({
      host   = string
      port   = string
      secret = string
    })
    shared   = object({
      host   = string
      secret = string
      path   = string
    })
    external = object({
      url    = string
      secret = string
    })
  })
  default     = {
    mongodb  = {
      url    = ""
      secret = ""
    }
    redis    = {
      url    = ""
      secret = ""
    }
    activemq = {
      host   = ""
      port   = ""
      secret = ""
    }
    shared   = {
      host   = ""
      secret = ""
      path   = "/data"
    }
    external = {
      url    = ""
      secret = ""
    }
  }
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type        = object({
    replicas          = number
    image             = string
    tag               = string
    image_pull_policy = string
    port              = number
  })
  default     = {
    replicas          = 1
    image             = "dockerhubaneo/armonik_control"
    tag               = "0.0.4"
    image_pull_policy = "IfNotPresent"
    port              = 5001
  }
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type        = object({
    replicas      = number
    # number of queues according to priority of tasks
    max_priority  = number
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
    worker        = list(object({
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
    replicas      = 1
    # number of queues according to priority of tasks
    max_priority  = 1
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
    # ArmoniK workers
    worker        = [
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
}
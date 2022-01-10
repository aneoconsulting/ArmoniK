#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
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
}

# Storage adapters
variable "storage_adapters" {
  description = "ArmoniK storage adapters"
  type        = object({
    object         = string
    table          = string
    queue          = string
    lease_provider = string
  })
}

# List of needed storage
variable "storage" {
  description = "List of storage needed by ArmoniK"
  type        = list(string)
}
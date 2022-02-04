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

# use Seq
variable "seq_endpoints" {
  description = "Endpoint URL of Seq"
  type        = object({
    url  = string
    host = string
    port = string
  })
}

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type        = object({
    image = string
    tag   = string
    name  = string
  })
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
}

# Endpoints and secrets of storage resources
variable "storage_endpoint_url" {
  description = "Endpoints and secrets of storage resources"
  type        = object({
    mongodb  = object({
      host   = string
      port   = string
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
      id     = string
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
  type        = object({
    data_type = object({
      object         = string
      table          = string
      queue          = string
      lease_provider = string
      shared         = string
      external       = string
    })
    list      = list(string)
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}
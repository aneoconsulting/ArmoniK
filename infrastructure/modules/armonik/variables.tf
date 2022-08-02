# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
}

# Monitoring
variable "monitoring" {
  description = "Monitoring info"
  type        = any
}

# Parameters of ingress
variable "ingress" {
  description = "Parameters of the ingress controller"
  type        = object({
    name               = string
    service_type       = string
    replicas           = number
    image              = string
    tag                = string
    image_pull_policy  = string
    http_port          = number
    grpc_port          = number
    limits             = object({
      cpu    = string
      memory = string
    })
    requests           = object({
      cpu    = string
      memory = string
    })
    image_pull_secrets = string
    node_selector      = any
    annotations        = any
    tls                = bool
    mtls               = bool
  })
  validation {
    error_message = "Ingress mTLS requires TLS to be enabled."
    condition     = var.ingress != null ? !var.ingress.mtls || var.ingress.tls : true
  }
  validation {
    error_message = "Without TLS, http_port and grpc_port must be different."
    condition     = var.ingress != null ? var.ingress.http_port != var.ingress.grpc_port || var.ingress.tls : true
  }
}

# Polling delay to MongoDB
# according to the size of the task and/or the application
variable "mongodb_polling_delay" {
  description = "Polling delay to MongoDB according to the size of the task and/or the application"
  type        = object({
    min_polling_delay = string
    max_polling_delay = string
  })
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type        = object({
    name               = string
    service_type       = string
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
    node_selector      = any
    annotations        = any
    hpa                = any
  })
}

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type        = object({
    api                = object({
      name     = string
      image    = string
      tag      = string
      port     = number
      limits   = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
    })
    app                = object({
      name     = string
      image    = string
      tag      = string
      port     = number
      limits   = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
    })
    service_type       = string
    replicas           = number
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
  })
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type        = map(object({
    replicas                         = number
    termination_grace_period_seconds = number
    image_pull_secrets               = string
    node_selector                    = any
    annotations                      = any
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
    hpa                              = any
  }))
}


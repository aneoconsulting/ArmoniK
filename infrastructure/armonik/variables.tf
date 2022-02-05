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

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type        = object({
    image = string
    tag   = string
    name  = string
  })
  default     = {
    name  = "fluent-bit"
    image = "fluent/fluent-bit"
    tag   = "1.3.11"
    name  = "fluent-bit"
  }
}

# Use monitoring
variable "monitoring" {
  description = "Use monitoring tools"
  type        = object({
    namespace  = string
    seq        = object({
      image         = string
      tag           = string
      node_selector = any
      use           = bool
    })
    grafana    = object({
      image = string
      tag   = string
      use   = bool
    })
    prometheus = object({
      image = string
      tag   = string
      use   = bool
    })
  })
  default     = {
    namespace  = "armonik-monitoring"
    seq        = {
      image         = "datalust/seq"
      tag           = "2021.4"
      node_selector = {}
      use           = true
    }
    grafana    = {
      image = "grafana/grafana"
      tag   = "latest"
      use   = false
    }
    prometheus = {
      image = "prom/prometheus"
      tag   = "latest"
      use   = false
    }
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
    object         = "Redis"
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
      secret = string
      id     = string
      path   = string
    })
    external = object({
      url    = string
      secret = string
    })
  })
  default     = {
    mongodb  = {
      host   = ""
      port   = ""
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
      id     = ""
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
    tag                = "0.0.4"
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
    worker                           = [
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

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}
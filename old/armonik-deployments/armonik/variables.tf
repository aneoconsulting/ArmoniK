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

# Secrets
variable "secrets"  {
  description = "Secrets parameters to retrieve storage credentials"
  type        = object({
    redis_username_secret = string
    redis_username_key    = string
    redis_password_secret = string
    redis_password_key    = string
    redis_certificate_secret = string
    redis_certificate_file = string

    mongodb_username_secret = string
    mongodb_username_key    = string
    mongodb_password_secret = string
    mongodb_password_key    = string
    mongodb_certificate_secret = string
    mongodb_certificate_file = string

    activemq_username_secret = string
    activemq_username_key    = string
    activemq_password_secret = string
    activemq_password_key    = string
    activemq_certificate_secret = string
    activemq_certificate_file = string
  })
  default     = {
    redis_username_secret = "redis-user"
    redis_username_key    = "username"
    redis_password_secret = "redis-user"
    redis_password_key    = "password"
    redis_certificate_secret = "redis-client-certificates"
    redis_certificate_file = "chain.pem"

    mongodb_username_secret = "mongodb-user"
    mongodb_username_key    = "username"
    mongodb_password_secret = "mongodb-user"
    mongodb_password_key    = "password"
    mongodb_certificate_secret = "mongodb-client-certificates"
    mongodb_certificate_file = "chain.pem"

    activemq_username_secret = "activemq-user"
    activemq_username_key    = "username"
    activemq_password_secret = "activemq-user"
    activemq_password_key    = "password"
    activemq_certificate_secret = "activemq-client-certificates"
    activemq_certificate_file = "chain.pem"
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
  })
  default     = {
    object         = "Redis"
    table          = "MongoDB"
    queue          = "Amqp"
    lease_provider = "MongoDB"
    shared         = "HostPath"
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

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}
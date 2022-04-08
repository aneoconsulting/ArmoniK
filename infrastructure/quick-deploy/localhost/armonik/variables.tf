# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
  type        = any
  default     = {}
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
  default     = "Information"
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
  default     = {}
}

# Monitoring
variable "monitoring" {
  description = "Endpoint URL of monitoring"
  type        = any
  default     = {}
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
  })
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type        = list(object({
    name                             = string
    replicas                         = number
    termination_grace_period_seconds = number
    image_pull_secrets               = string
    node_selector                    = any
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
    hpa                              = object({
      min_replicas   = number
      max_replicas   = number
      object_metrics = list(object({
        described_object = object({
          api_version = string
          kind        = string
        })
        metric_name      = string
        target           = object({
          type                = string
          average_value       = number
          average_utilization = number
          value               = number
        })
      }))
    })
  }))
}
# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector"
  type        = any
  default     = {}
}

# Metrics exporter info
variable "metrics_exporter" {
  description = "Metrics exporter infos"
  type        = object({
    name  = string
    image = string
    tag   = string
  })
  default     = {
    name  = "armonik-metrics-exporter"
    image = ""
    tag   = ""
  }
}

# API service info
variable "api_service" {
  description = "API service info"
  type        = object({
    name                     = string
    group                    = string
    group_priority_minimum   = number
    version                  = string
    version_priority         = number
    insecure_skip_tls_verify = bool
  })
  default     = {
    name                     = "armonik-api-service"
    group                    = "custom.metrics.k8s.io"
    group_priority_minimum   = 1000
    version                  = "v1beta1"
    version_priority         = 5
    insecure_skip_tls_verify = true
  }
}

# HPA infos
variable "hpa" {
  description = "HPA info"
  type        = object({
    name             = string
    replicas         = object({
      min = number
      max = number
    })
    scale_target_ref = object({
      kind = string
      name = string
    })
    metric           = object({
      name   = string
      target = object({
        type                = string # Utilization, Value, or AverageValue
        average_value       = number
        average_utilization = number
        value               = number
      })
    })
  })
}
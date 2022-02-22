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

# Monitoring infos
variable "monitoring" {
  description = "Monitoring infos"
  type        = object({
    seq        = object({
      image        = string
      tag          = string
      service_type = string
      use          = bool
    })
    grafana    = object({
      image        = string
      tag          = string
      service_type = string
      use          = bool
    })
    prometheus = object({
      image         = string
      tag           = string
      service_type  = string
      use           = bool
      node_exporter = object({
        image = string
        tag   = string
      })
    })
    fluent_bit = object({
      image          = string
      tag            = string
      is_daemonset   = bool
      http_port      = number
      read_from_head = string
    })
  })
}
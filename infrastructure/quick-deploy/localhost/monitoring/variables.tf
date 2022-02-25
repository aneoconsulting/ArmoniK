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

# Monitoring infos
variable "monitoring" {
  description = "Monitoring infos"
  type        = object({
    seq           = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      service_type       = string
      enabled            = bool
      node_selector      = any
    })
    grafana       = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      service_type       = string
      enabled            = bool
      node_selector      = any
    })
    node_exporter = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      enabled            = bool
      node_selector      = any
    })
    prometheus    = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      service_type       = string
      enabled            = bool
      node_selector      = any
    })
    fluent_bit    = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      is_daemonset       = bool
      http_port          = number
      read_from_head     = string
      node_selector      = any
    })
  })
}
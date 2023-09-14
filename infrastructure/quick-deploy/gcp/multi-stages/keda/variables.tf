# GKE
variable "gke" {
  description = "GKE info"
  type        = any
  default     = {}
}

# GAR
variable "gar" {
  description = "GAR info"
  type        = any
  default     = {}
}

# SUFFIX
variable "suffix" {
  description = "To suffix the AWS resources"
  type        = string
  default     = "main"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for Keda"
  type        = string
  default     = "default"
}

# Keda
variable "keda" {
  description = "Keda configuration"
  type = object({
    image_name                      = optional(string, "ghcr.io/kedacore/keda"),
    image_tag                       = optional(string, "2.9.3"),
    apiserver_image_name            = optional(string, "ghcr.io/kedacore/keda-metrics-apiserver"),
    apiserver_image_tag             = optional(string, "2.9.3"),
    pull_secrets                    = optional(string, ""),
    node_selector                   = optional(any, {})
    metrics_server_dns_policy       = optional(string, "ClusterFirst")
    metrics_server_use_host_network = optional(bool, false)
    helm_chart_repository           = optional(string, "https://kedacore.github.io/charts")
    helm_chart_version              = optional(string, "2.9.4")
  })
  default = {}
}
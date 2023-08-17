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

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type        = map(string)
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type        = map(set(string))
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}

variable "helm_charts" {
  description = "Versions of helm charts repositories"
  type = map(object({
    repository = string
    version    = string
  }))
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "default"
}

# Keda infos
variable "keda" {
  description = "Keda infos"
  type = object({
    image_name                      = optional(string, "ghcr.io/kedacore/keda"),
    image_tag                       = optional(string),
    apiserver_image_name            = optional(string, "ghcr.io/kedacore/keda-metrics-apiserver"),
    apiserver_image_tag             = optional(string),
    image_pull_secrets              = optional(string, "")
    node_selector                   = optional(map(string), {})
    metrics_server_dns_policy       = optional(string, "ClusterFirst")
    metrics_server_use_host_network = optional(bool, false)
    helm_chart_repository           = optional(string)
    helm_chart_version              = optional(string)
  })
  default = {}
}
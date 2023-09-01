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

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type        = map(string)
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type        = map(set(string))
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for metrics server"
  type        = string
  default     = "kube-system"
}

variable "metrics_server" {
  description = "metrics-server infos"
  type = object({
    image_name            = optional(string, "registry.k8s.io/metrics-server/metrics-server"),
    image_tag             = optional(string),
    image_pull_secrets    = optional(string, "")
    node_selector         = optional(map(string), {})
    host_network          = optional(bool, false)
    helm_chart_repository = optional(string)
    helm_chart_version    = optional(string)
    args = optional(set(string), [
      "--cert-dir=/tmp",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
      "--kubelet-insecure-tls"
    ])
  })
  default = {}
}
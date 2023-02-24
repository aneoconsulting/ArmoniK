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

# Keda infos
variable "keda" {
  description = "Keda infos"
  type = object({
    docker_image = object({
      keda = object({
        image = string
        tag   = string
      })
      metricsApiServer = object({
        image = string
        tag   = string
      })
    })
    image_pull_secrets    = string
    node_selector         = any
    helm_chart_repository = optional(string, "https://kedacore.github.io/charts")
    helm_chart_version    = optional(string, "2.9.4")
  })
}
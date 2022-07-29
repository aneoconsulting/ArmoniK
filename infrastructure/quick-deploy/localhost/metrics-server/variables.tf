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
  description = "Kubernetes namespace for metrics server"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for metrics server"
  type        = object({
    image = string
    tag   = string
  })
}

# image pull secrets
variable "image_pull_secrets" {
  description = "image_pull_secrets for metrics server"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector for metrics server"
  type        = any
}

# Args
variable "args" {
  description = "Arguments for metrics server"
  type        = list(string)
}

# Host network
variable "host_network" {
  description = "Host network for metrics server"
  type        = bool
}
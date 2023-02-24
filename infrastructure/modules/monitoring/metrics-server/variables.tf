# Namespace
variable "namespace" {
  description = "Namespace of metrics server"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for metrics server"
  type = object({
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

# Default args
variable "default_args" {
  description = "Default args for metrics server"
  type        = list(string)
}

# Host network
variable "host_network" {
  description = "Host network for metrics server"
  type        = bool
}

# Repository of helm chart
variable "helm_chart_repository" {
  description = "Path to helm chart repository for metrics server"
  type        = string
}

# Version of helm chart
variable "helm_chart_version" {
  description = "Version of chart helm for metrics server"
  type        = string
}

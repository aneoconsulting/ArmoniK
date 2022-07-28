# Namespace
variable "namespace" {
  description = "Namespace of metrics server"
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
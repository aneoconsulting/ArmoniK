# Namespace
variable "namespace" {
  description = "Namespace of Keda"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Keda"
  type        = object({
    keda             = object({
      image = string
      tag   = string
    })
    metricsApiServer = object({
      image = string
      tag   = string
    })
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for Prometheus adapter"
  type        = any
}
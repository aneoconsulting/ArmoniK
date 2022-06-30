# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Port
variable "port" {
  description = "Port for Grafana service"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Grafana"
  type        = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for Grafana"
  type        = any
  default     = {}
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# Prometheus url
variable "prometheus_url" {
  description = "Prometheus URL"
  type        = string
}

# Enable authentication
variable "authentication" {
  description = "Enables the authentication form"
  type        = bool
  default     = false
}

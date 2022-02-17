# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Prometheus"
  type        = object({
    image = string
    tag   = string
  })
  default     = {
    image = "prom/prometheus"
    tag   = "latest"
  }
}

# Parameters for prometheus
variable "prometheus" {
  description = "Parameters of prometheus"
  type        = object({
    replicas = number
    port     = object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    })
  })
  default     = {
    replicas = 1
    port     = {
      name        = "prometheus"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }
  }
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}
# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Grafana"
  type        = object({
    image = string
    tag   = string
  })
  default     = {
    image = "grafana/grafana"
    tag   = "latest"
  }
}

# Parameters for Grafana
variable "grafana" {
  description = "Parameters of Grafana"
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
      name        = "grafana"
      port        = 3000
      target_port = 3000
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
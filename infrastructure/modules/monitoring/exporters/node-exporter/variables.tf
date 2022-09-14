# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for node exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for node exporter"
  type        = any
  default     = {}
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}
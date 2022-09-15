# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
}

# Docker image
variable "docker_image" {
  description = "Docker image for Metrics exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for Metrics exporter"
  type        = any
  default     = {}
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
}
